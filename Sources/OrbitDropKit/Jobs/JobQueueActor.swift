import Foundation

public enum JobQueueError: LocalizedError, Sendable {
    case jobNotFound(UUID)
    case timedOut(UUID)

    public var errorDescription: String? {
        switch self {
        case .jobNotFound(let id):
            return "Job \(id) não encontrado na fila."
        case .timedOut(let id):
            return "Tempo limite excedido aguardando o job \(id)."
        }
    }
}

public actor JobQueueActor {
    public let maxConcurrency: Int
    private var jobs: [UUID: OperationJob] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    public init(maxConcurrency: Int = 4) {
        self.maxConcurrency = max(1, maxConcurrency)
    }

    /// Enfileira um novo job de processamento e inicia a execução em background.
    public func enqueue(
        inputs: [URL],
        targetExtension: String,
        directory: URL? = nil
    ) -> UUID {
        let job = OperationJob(
            inputs: inputs,
            targetExtension: targetExtension,
            directory: directory
        )
        let id = job.id
        jobs[id] = job

        let task = Task { [weak self, id, inputs, targetExtension, directory] in
            guard let self = self else { return }
            await self.runJob(id: id, inputs: inputs, targetExtension: targetExtension, directory: directory)
        }
        activeTasks[id] = task

        return id
    }

    /// Cancela um job em andamento ou enfileirado.
    public func cancel(jobID: UUID) {
        if let task = activeTasks[jobID] {
            task.cancel()
            activeTasks.removeValue(forKey: jobID)
        }
        if var job = jobs[jobID], job.status != .completed {
            job.status = .cancelled
            jobs[jobID] = job
        }
    }

    /// Retorna o status atual de um job.
    public func jobStatus(jobID: UUID) -> JobStatus? {
        jobs[jobID]?.status
    }

    /// Retorna uma cópia do snapshot do job.
    public func getJob(jobID: UUID) -> OperationJob? {
        jobs[jobID]
    }

    /// Aguarda a finalização de um job (útil para testes e sincronização).
    public func waitForCompletion(jobID: UUID, timeoutSeconds: Double = 10.0) async throws -> OperationJob {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if let job = jobs[jobID] {
                if job.status == .completed || job.status == .failed || job.status == .cancelled {
                    return job
                }
            }
            try await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }
        throw JobQueueError.timedOut(jobID)
    }

    private func updateProgress(id: UUID, progress: Double, outputs: [URL]) {
        guard var job = jobs[id], job.status == .running else { return }
        job.progress = progress
        job.outputURLs = outputs
        jobs[id] = job
    }

    private func finishJob(id: UUID, status: JobStatus, outputs: [URL], error: String? = nil) {
        guard var job = jobs[id] else { return }
        job.status = status
        job.progress = (status == .completed) ? 1.0 : job.progress
        job.outputURLs = outputs
        job.errorMessage = error
        jobs[id] = job
        activeTasks.removeValue(forKey: id)
    }

    private func runJob(
        id: UUID,
        inputs: [URL],
        targetExtension: String,
        directory: URL?
    ) async {
        guard var job = jobs[id] else { return }
        job.status = .running
        jobs[id] = job

        let cleanTarget = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()

        // Se múltiplos arquivos ou lote de imagens for convertido para PDF, consolida em 1 único documento
        if cleanTarget == "pdf" {
            let imageExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "bmp", "webp", "avif"]
            let allImages = inputs.allSatisfy { imageExtensions.contains($0.pathExtension.lowercased()) }
            if allImages && !inputs.isEmpty {
                do {
                    let pdf = try ImageToPDFConverter.createPDF(from: inputs, outputDirectory: directory)
                    finishJob(id: id, status: .completed, outputs: [pdf])
                    return
                } catch {
                    finishJob(id: id, status: .failed, outputs: [], error: error.localizedDescription)
                    return
                }
            }
        }

        var outputs: [URL] = []
        let total = Double(inputs.count)
        var completedCount = 0.0

        for input in inputs {
            if jobs[id]?.status == .cancelled || Task.isCancelled {
                finishJob(id: id, status: .cancelled, outputs: outputs)
                return
            }

            // Desacopla a computação fora do executor do ator
            let convertedResult: Result<[URL], Error> = await Task.detached(priority: .userInitiated) {
                do {
                    let srcExt = input.pathExtension.lowercased()
                    let cleanTarget = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()

                    if cleanTarget == "mp4" || cleanTarget == "mov" {
                        let out = try await VideoTranscoder.transcode(sourceURL: input, targetExtension: cleanTarget, directory: directory)
                        return .success([out])
                    } else if cleanTarget == "m4a" && (srcExt == "mp4" || srcExt == "mov") {
                        let out = try await VideoTranscoder.extractAudio(sourceURL: input, directory: directory)
                        return .success([out])
                    } else if (cleanTarget == "wav" || cleanTarget == "aiff" || cleanTarget == "stereo") && (srcExt == "wav" || srcExt == "aiff" || srcExt == "m4a") {
                        let out = try AudioChannelConverter.convertChannels(sourceURL: input, targetChannels: 2, directory: directory)
                        return .success([out])
                    } else if (cleanTarget == "mono") && (srcExt == "wav" || srcExt == "aiff" || srcExt == "m4a") {
                        let out = try AudioChannelConverter.convertChannels(sourceURL: input, targetChannels: 1, directory: directory)
                        return .success([out])
                    } else if cleanTarget == "m4a" && (srcExt == "wav" || srcExt == "aiff") {
                        let out = try await VideoTranscoder.extractAudio(sourceURL: input, directory: directory)
                        return .success([out])
                    } else if srcExt == "pdf" && (cleanTarget == "png" || cleanTarget == "jpg" || cleanTarget == "jpeg") {
                        let pages = try PDFRasterizer.renderPages(sourceURL: input, dpi: 300, format: cleanTarget == "png" ? .png : .jpeg, directory: directory)
                        return .success(pages)
                    } else if srcExt == "pdf" && (cleanTarget == "txt" || cleanTarget == "md") {
                        let out = try PDFTextExtractor.extractText(sourceURL: input, format: cleanTarget == "md" ? .markdown : .text, directory: directory)
                        return .success([out])
                    } else if (srcExt == "srt" && cleanTarget == "vtt") || (srcExt == "vtt" && cleanTarget == "srt") {
                        let format: SubtitleFormat = (cleanTarget == "vtt") ? .vtt : .srt
                        let out = try SubtitleConverter.convert(sourceURL: input, targetFormat: format, directory: directory)
                        return .success([out])
                    } else if cleanTarget == "zip" {
                        let out = try ArchiveProcessor.createZIP(sources: [input], directory: directory)
                        return .success([out])
                    } else if cleanTarget == "tar.gz" || cleanTarget == "tar" {
                        let out = try ArchiveProcessor.createTar(sources: [input], gzip: cleanTarget.contains("gz"), directory: directory)
                        return .success([out])
                    } else if cleanTarget == "md" {
                        let out = try MarkdownConverter.convertToMarkdown(sourceURL: input, directory: directory)
                        return .success([out])
                    } else if cleanTarget == "pdf" {
                        let out = try ImageToPDFConverter.createPDF(from: [input], outputDirectory: directory)
                        return .success([out])
                    } else {
                        let out = try ImagePipeline.convert(
                            sourceURL: input,
                            targetExtension: cleanTarget,
                            directory: directory
                        )
                        return .success([out])
                    }
                } catch {
                    return .failure(error)
                }
            }.value

            if jobs[id]?.status == .cancelled || Task.isCancelled {
                finishJob(id: id, status: .cancelled, outputs: outputs)
                return
            }

            switch convertedResult {
            case .success(let outList):
                outputs.append(contentsOf: outList)
            case .failure(let err):
                NSLog("[JobQueue] Erro ao converter %@: %@", input.lastPathComponent, err.localizedDescription)
            }

            completedCount += 1.0
            updateProgress(id: id, progress: total > 0 ? (completedCount / total) : 1.0, outputs: outputs)
        }

        if outputs.isEmpty && !inputs.isEmpty {
            finishJob(id: id, status: .failed, outputs: [], error: "Todos os arquivos falharam na conversão.")
        } else {
            finishJob(id: id, status: .completed, outputs: outputs)
        }
    }
}
