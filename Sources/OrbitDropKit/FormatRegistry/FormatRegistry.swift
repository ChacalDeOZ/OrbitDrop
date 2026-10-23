import Foundation
import UniformTypeIdentifiers

public final class FormatRegistry: Sendable {
    public let edges: [FormatEdge]

    public init(edges: [FormatEdge]) {
        self.edges = edges
    }

    /// Retorna registro padrão pré-populado com as arestas reais implementadas.
    public static func defaultRegistry() -> FormatRegistry {
        var list: [FormatEdge] = []

        // Formatos de imagem suportados como entrada no ImagePipeline
        let imageSources: [(UTType, [String])] = [
            (.png, ["jpg", "jpeg", "tiff", "bmp", "png"]),
            (.jpeg, ["png", "tiff", "bmp", "jpg"]),
            (.heic, ["jpg", "jpeg", "png", "tiff", "bmp"]),
            (.tiff, ["jpg", "jpeg", "png", "bmp", "tiff"]),
            (.bmp, ["jpg", "jpeg", "png", "tiff", "bmp"])
        ]

        let extMap: [String: (UTType, String, String)] = [
            "jpg": (.jpeg, "JPEG", "photo"),
            "jpeg": (.jpeg, "JPEG", "photo"),
            "png": (.png, "PNG", "photo.fill"),
            "tiff": (.tiff, "TIFF", "doc.richtext"),
            "bmp": (.bmp, "BMP", "doc.fill"),
            "mp4": (.mpeg4Movie, "MP4", "video"),
            "mov": (.quickTimeMovie, "MOV", "video.fill"),
            "m4a": (.mpeg4Audio, "M4A", "music.note"),
            "wav": (.wav, "WAV", "waveform"),
            "aiff": (.aiff, "AIFF", "waveform.path"),
            "pdf": (.pdf, "PDF", "doc.richtext"),
            "txt": (.plainText, "Texto (TXT)", "doc.text"),
            "md": (UTType(filenameExtension: "md") ?? .plainText, "Markdown", "text.badge.checkmark"),
            "vtt": (UTType(filenameExtension: "vtt") ?? .plainText, "VTT", "captions.bubble"),
            "srt": (UTType(filenameExtension: "srt") ?? .plainText, "SRT", "captions.bubble.fill"),
            "zip": (.zip, "ZIP", "archivebox")
        ]

        for (sourceType, targetExts) in imageSources {
            for targetExt in targetExts {
                if let info = extMap[targetExt] {
                    list.append(
                        FormatEdge(
                            sourceType: sourceType,
                            targetExtension: targetExt,
                            targetType: info.0,
                            family: .image,
                            title: info.1,
                            iconName: info.2,
                            supportsBatch: true
                        )
                    )
                }
            }
        }

        // Fontes de vídeo
        let videoSources: [(UTType, [String])] = [
            (.mpeg4Movie, ["mov", "mp4", "m4a"]),
            (.quickTimeMovie, ["mp4", "mov", "m4a"])
        ]
        for (sourceType, targetExts) in videoSources {
            for targetExt in targetExts {
                if let info = extMap[targetExt] {
                    list.append(
                        FormatEdge(
                            sourceType: sourceType,
                            targetExtension: targetExt,
                            targetType: info.0,
                            family: (targetExt == "m4a") ? .audio : .video,
                            title: info.1,
                            iconName: info.2,
                            supportsBatch: true
                        )
                    )
                }
            }
        }

        // Fontes de áudio
        let audioSources: [(UTType, [String])] = [
            (.wav, ["wav", "m4a", "aiff"]),
            (.aiff, ["wav", "m4a", "aiff"]),
            (.mpeg4Audio, ["wav", "m4a", "aiff"])
        ]
        for (sourceType, targetExts) in audioSources {
            for targetExt in targetExts {
                if let info = extMap[targetExt] {
                    list.append(
                        FormatEdge(
                            sourceType: sourceType,
                            targetExtension: targetExt,
                            targetType: info.0,
                            family: .audio,
                            title: info.1,
                            iconName: info.2,
                            supportsBatch: true
                        )
                    )
                }
            }
        }

        // Fontes de PDF
        let pdfSources: [(UTType, [String])] = [
            (.pdf, ["png", "jpg", "txt", "md"])
        ]
        for (sourceType, targetExts) in pdfSources {
            for targetExt in targetExts {
                if let info = extMap[targetExt] {
                    list.append(
                        FormatEdge(
                            sourceType: sourceType,
                            targetExtension: targetExt,
                            targetType: info.0,
                            family: .pdf,
                            title: info.1,
                            iconName: info.2,
                            supportsBatch: true
                        )
                    )
                }
            }
        }

        // Fontes de legendas
        if let srtType = UTType(filenameExtension: "srt"), let vttType = UTType(filenameExtension: "vtt") {
            if let vttInfo = extMap["vtt"] {
                list.append(FormatEdge(sourceType: srtType, targetExtension: "vtt", targetType: vttInfo.0, family: .subtitle, title: vttInfo.1, iconName: vttInfo.2))
            }
            if let srtInfo = extMap["srt"] {
                list.append(FormatEdge(sourceType: vttType, targetExtension: "srt", targetType: srtInfo.0, family: .subtitle, title: srtInfo.1, iconName: srtInfo.2))
            }
        }

        // Fontes de arquivos e pastas para compactação ZIP
        if let zipInfo = extMap["zip"] {
            list.append(FormatEdge(sourceType: .data, targetExtension: "zip", targetType: .zip, family: .archive, title: zipInfo.1, iconName: zipInfo.2))
            list.append(FormatEdge(sourceType: .folder, targetExtension: "zip", targetType: .zip, family: .archive, title: zipInfo.1, iconName: zipInfo.2))
            list.append(FormatEdge(sourceType: .item, targetExtension: "zip", targetType: .zip, family: .archive, title: zipInfo.1, iconName: zipInfo.2))
        }

        return FormatRegistry(edges: list)
    }

    /// Calcula os alvos radiais comuns compatíveis com TODOS os arquivos selecionados.
    public func availableTargets(for files: [FileDescriptor]) -> [RadialItem] {
        guard !files.isEmpty else { return [] }

        // Helper para testar conformidade
        func supports(file: FileDescriptor, edge: FormatEdge) -> Bool {
            if edge.targetExtension == "zip" {
                return true
            }
            if file.isDirectory { return false }
            guard file.contentType != .data else { return false }
            return file.contentType.conforms(to: edge.sourceType)
        }

        // Para o primeiro arquivo, descobre os destinos suportados
        var commonTargetsMap: [String: (title: String, icon: String)] = [:]

        let firstFile = files[0]
        let firstTargets = edges.filter { supports(file: firstFile, edge: $0) }

        for edge in firstTargets {
            let key = edge.targetExtension == "jpeg" ? "jpg" : edge.targetExtension
            commonTargetsMap[key] = (edge.title, edge.iconName)
        }

        // Interseção com os arquivos subsequentes
        for file in files.dropFirst() {
            let supportedByThisFile = Set(
                edges.filter { supports(file: file, edge: $0) }.map { edge -> String in
                    edge.targetExtension == "jpeg" ? "jpg" : edge.targetExtension
                }
            )

            commonTargetsMap = commonTargetsMap.filter { supportedByThisFile.contains($0.key) }
            if commonTargetsMap.isEmpty {
                return []
            }
        }

        // Mapeia para RadialItem estável e ordenado
        return commonTargetsMap.sorted(by: { $0.key < $1.key }).map { (key, val) in
            RadialItem(
                id: "convert.\(key)",
                title: val.title,
                iconName: val.icon,
                targetExtension: key,
                isAvailable: true
            )
        }
    }
}
