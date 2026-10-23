import Foundation
import AppKit
import AVFoundation
import ImageIO
import OrbitDropKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var radialPanelController: RadialPanelController?
    private var dropZoneController: DropZoneWindowController?
    private var floatShelfController: FloatShelfController?
    private var dragDetector: DragIntentDetector?

    private let formatRegistry = FormatRegistry.defaultRegistry()
    private let jobQueue = JobQueueActor(maxConcurrency: 4)

    private var defaultConvertItems: [RadialItem] {
        // Fallback para quando nenhum arquivo prévio estiver inferido
        let samplePNG = FileDescriptor(url: URL(fileURLWithPath: "/tmp/sample.png"))
        return formatRegistry.availableTargets(for: [samplePNG])
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // App residente em barra de menus sem ícone no Dock
        NSApp.setActivationPolicy(.accessory)

        let statusController = StatusItemController()
        let radialController = RadialPanelController()
        let dropZone = DropZoneWindowController()
        let floatShelf = FloatShelfController()
        let detector = DragIntentDetector()

        self.statusItemController = statusController
        self.radialPanelController = radialController
        self.dropZoneController = dropZone
        self.floatShelfController = floatShelf
        self.dragDetector = detector

        // Callbacks do menu de status
        statusController.onTestRadialTriggered = { [weak self] in
            guard let self = self else { return }
            let mouseLoc = NSEvent.mouseLocation
            radialController.show(at: mouseLoc, mode: .convert, items: self.defaultConvertItems, forceReposition: true)
        }

        statusController.onOpenDropZoneTriggered = {
            dropZone.show()
        }

        statusController.onOpenFloatShelfTriggered = {
            floatShelf.show()
        }

        statusController.onOpenSettingsTriggered = {
            SettingsWindowController.shared.show()
        }

        statusController.onOpenOnboardingTriggered = {
            OnboardingWindowController.shared.show()
        }

        // Intenção de arrasto detectada (Shift, Command, Control)
        detector.onModeTriggered = { [weak self] mode, cursor in
            guard let self = self else { return }
            let items: [RadialItem]
            switch mode {
            case .convert:
                // Resolver formatos diretamente do pasteboard da sessão de drag do Finder.
                let draggedURLs = DragPayloadProbe.currentFileURLs()
                if draggedURLs.isEmpty {
                    items = self.defaultConvertItems
                } else {
                    let descriptors = draggedURLs.map { FileDescriptor(url: $0) }
                    let contextual = self.formatRegistry.availableTargets(for: descriptors)
                    items = contextual.isEmpty ? self.defaultConvertItems : contextual
                }
            case .tools:
                items = [
                    RadialItem(id: "tool.compress", title: "Comprimir", iconName: "arrow.down.circle", targetExtension: "jpg"),
                    RadialItem(id: "tool.metadata", title: "Metadados", iconName: "info.circle", targetExtension: ""),
                    RadialItem(id: "tool.pdf.merge", title: "Juntar PDFs", iconName: "doc.on.doc", targetExtension: ""),
                    RadialItem(id: "tool.pdf.split", title: "Dividir PDF", iconName: "scissors", targetExtension: ""),
                    RadialItem(id: "tool.pdf.organize", title: "Organizar Páginas", iconName: "arrow.up.and.down.and.arrow.left.and.right", targetExtension: ""),
                    RadialItem(id: "tool.video.trim", title: "Cortar Vídeo", iconName: "film", targetExtension: ""),
                    RadialItem(id: "tool.video.join", title: "Juntar Vídeos", iconName: "film.stack", targetExtension: ""),
                    RadialItem(id: "tool.audio.normalize", title: "Normalizar", iconName: "waveform", targetExtension: ""),
                    RadialItem(id: "tool.audio.visualizer", title: "Visualizer", iconName: "waveform.path.ecg", targetExtension: ""),
                    RadialItem(id: "tool.qr", title: "Ler QR", iconName: "qrcode.viewfinder", targetExtension: ""),
                    RadialItem(id: "tool.pdf", title: "Fotos para PDF", iconName: "doc.richtext", targetExtension: "")
                ]
            case .actions:
                items = ActionDispatcher.availableActions()
            }
            radialController.show(at: cursor, mode: mode, items: items)
        }

        detector.onDragCancelled = {
            radialController.hide()
        }

        detector.onNavigateNext = { [weak self] in
            guard let self = self, self.radialPanelController?.isVisible == true else { return }
            let wheel = self.radialPanelController!.wheelView
            wheel.activeSectorIndex = KeyboardNavigator.nextIndex(current: wheel.activeSectorIndex, count: wheel.items.count)
        }

        detector.onNavigatePrevious = { [weak self] in
            guard let self = self, self.radialPanelController?.isVisible == true else { return }
            let wheel = self.radialPanelController!.wheelView
            wheel.activeSectorIndex = KeyboardNavigator.previousIndex(current: wheel.activeSectorIndex, count: wheel.items.count)
        }

        detector.onSelectActive = { [weak self] in
            guard let self = self, self.radialPanelController?.isVisible == true else { return }
            let wheel = self.radialPanelController!.wheelView
            if let idx = wheel.activeSectorIndex, idx < wheel.items.count {
                let item = wheel.items[idx]
                self.radialPanelController?.hide()
                self.promptAndProcess(for: item)
            }
        }

        detector.onMouseUp = { [weak self] location in
            guard let self = self, self.radialPanelController?.isVisible == true else { return }
            let wheel = self.radialPanelController!.wheelView

            // Se o botão do mouse foi solto em cima de um setor válido, seleciona e processa
            if let frame = self.radialPanelController?.panel.frame, frame.contains(location) {
                let localPoint = wheel.convert(wheel.window?.mouseLocationOutsideOfEventStream ?? location, from: nil)
                let center = CGPoint(x: wheel.bounds.midX, y: wheel.bounds.midY)
                if let sectorIdx = RadialGeometry.sectorIndex(
                    at: localPoint,
                    center: center,
                    sectorCount: wheel.items.count,
                    innerRadius: wheel.innerRadius,
                    outerRadius: wheel.outerRadius
                ), sectorIdx < wheel.items.count {
                    let selectedItem = wheel.items[sectorIdx]
                    self.radialPanelController?.hide()
                    self.promptAndProcess(for: selectedItem)
                    return
                }
            }

            // Se soltou fora ou no centro, fecha imediatamente o menu
            self.radialPanelController?.hide()
        }

        // Drop na roda radial
        radialController.wheelView.onDropConfirmed = { [weak self] item, urls in
            self?.handleFilesDroppedOnItem(item: item, urls: urls)
            radialController.hide()
        }

        // Clique direto no setor da roda
        radialController.wheelView.onSectorSelected = { [weak self] item in
            guard let self = self else { return }
            radialController.hide()
            self.promptAndProcess(for: item)
        }

        // Clique fora / centro neutro
        radialController.wheelView.onDismissRequested = {
            radialController.hide()
        }

        // Drop na janela de drop zone flutuante
        dropZone.onFilesDropped = { [weak self] urls in
            self?.processConversionJob(urls: urls, targetExtension: "jpg")
        }

        statusController.setupStatusItem()
        detector.startMonitoring()

        // Exibir onboarding automaticamente apenas no primeiro launch
        if !OnboardingState.shared.hasCompletedOnboarding {
            OnboardingWindowController.shared.show()
        }
    }

    private func handleFilesDroppedOnItem(item: RadialItem, urls: [URL]) {
        if item.id.hasPrefix("action.") {
            ActionDispatcher.dispatch(
                actionID: item.id,
                files: urls,
                sourceView: radialPanelController?.wheelView,
                floatShelf: floatShelfController
            )
            return
        }

        if item.id.hasPrefix("tool.") {
            processImageTool(itemID: item.id, urls: urls)
            return
        }

        processConversionJob(urls: urls, targetExtension: item.targetExtension)
    }

    private func processImageTool(itemID: String, urls: [URL]) {
        let settings = SettingsManager.shared.settings
        let outputDir = settings.customOutputDirectory.map { URL(fileURLWithPath: $0) }

        Task.detached(priority: .userInitiated) {
            var outputs: [URL] = []
            do {
                switch itemID {
                case "tool.compress":
                    for url in urls {
                        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                        let size = (attrs[.size] as? NSNumber)?.int64Value ?? 1_000_000
                        outputs.append(try ImageCompressor.compress(sourceURL: url, targetBytes: max(10_000, size / 2), directory: outputDir))
                    }
                case "tool.metadata":
                    for url in urls { outputs.append(try MetadataEditor.stripAllMetadata(sourceURL: url, directory: outputDir)) }
                case "tool.adjust":
                    for url in urls { outputs.append(try ImageAdjustments.apply(sourceURL: url, contrast: 1.1, saturation: 1.05, directory: outputDir)) }
                case "tool.annotate":
                    for url in urls {
                        let annotation = AnnotationItem.text("OrbitDrop", at: CGPoint(x: 12, y: 12), color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                        outputs.append(try ImageAnnotator.annotate(sourceURL: url, annotations: [annotation], directory: outputDir))
                    }
                case "tool.background":
                    for url in urls { outputs.append(try ImageBackgroundAdder.addBackground(sourceURL: url, directory: outputDir)) }
                case "tool.crop":
                    for url in urls {
                        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
                        let side = CGFloat(min(image.width, image.height))
                        let rect = CGRect(x: (CGFloat(image.width) - side) / 2, y: (CGFloat(image.height) - side) / 2, width: side, height: side)
                        outputs.append(try ImageCropper.crop(sourceURL: url, cropRect: rect, directory: outputDir))
                    }
                case "tool.redact":
                    for url in urls {
                        let regions = try ImageRedactor.detectFaceRegions(sourceURL: url)
                        outputs.append(try ImageRedactor.redact(sourceURL: url, regions: regions, directory: outputDir))
                    }
                case "tool.collage":
                    outputs.append(try ImageCollageBuilder.createCollage(sources: urls, directory: outputDir))
                case "tool.qr":
                    var messages: [String] = []
                    for url in urls { messages.append(contentsOf: try await QRCodeReader.read(from: url)) }
                    await MainActor.run { self.showQRResults(messages) }
                    return
                case "tool.pdf":
                    outputs.append(try ImageToPDFConverter.createPDF(from: urls, outputDirectory: outputDir))
                case "tool.pdf.merge":
                    outputs.append(try PDFMerger.merge(sources: urls, directory: outputDir))
                case "tool.pdf.split":
                    for url in urls {
                        outputs.append(contentsOf: try PDFSplitter.split(sourceURL: url, directory: outputDir))
                    }
                case "tool.pdf.organize":
                    for url in urls {
                        // Rotação padrão de 90° para demonstração rápida
                        outputs.append(try PDFPageOrganizer.reorganize(sourceURL: url, actions: [.rotate(pageIndex: 0, degrees: 90)], directory: outputDir))
                    }
                case "tool.video.trim":
                    for url in urls {
                        let asset = AVURLAsset(url: url)
                        let duration = CMTimeGetSeconds(try await asset.load(.duration))
                        outputs.append(try await VideoTrimmer.trim(sourceURL: url, startTimeSeconds: 0, durationSeconds: max(0.5, duration / 2.0), directory: outputDir))
                    }
                case "tool.video.join":
                    outputs.append(try await VideoJoiner.join(sources: urls, directory: outputDir))
                case "tool.video.crop":
                    for url in urls {
                        outputs.append(try await VideoCropper.crop(sourceURL: url, cropRect: CGRect(x: 10, y: 10, width: 200, height: 200), directory: outputDir))
                    }
                case "tool.video.redact":
                    for url in urls {
                        outputs.append(try await VideoRedactor.redact(sourceURL: url, regions: [CGRect(x: 20, y: 20, width: 80, height: 80)], directory: outputDir))
                    }
                case "tool.video.speed":
                    for url in urls {
                        outputs.append(try await VideoSpeedController.changeSpeed(sourceURL: url, speedFactor: 2.0, directory: outputDir))
                    }
                case "tool.video.frames":
                    for url in urls {
                        outputs.append(try await VideoFrameExtractor.extractFrame(sourceURL: url, atSeconds: 0.0, directory: outputDir))
                    }
                case "tool.video.split":
                    for url in urls {
                        outputs.append(contentsOf: try await VideoSplitter.split(sourceURL: url, partsCount: 2, directory: outputDir))
                    }
                case "tool.audio.normalize":
                    for url in urls {
                        outputs.append(try AudioNormalizer.normalize(sourceURL: url, targetPeakDBFS: -1.0, directory: outputDir))
                    }
                case "tool.audio.visualizer":
                    for url in urls {
                        outputs.append(try await AudioVisualizer.createVisualizerVideo(audioURL: url, outputDirectory: outputDir))
                    }
                case "tool.audio.trim":
                    for url in urls {
                        outputs.append(try AudioTrimmer.trim(sourceURL: url, startTimeSeconds: 0, durationSeconds: 5.0, directory: outputDir))
                    }
                case "tool.audio.channels":
                    for url in urls {
                        outputs.append(try AudioChannelConverter.convertChannels(sourceURL: url, targetChannels: 1, directory: outputDir))
                    }
                case "tool.audio.bleep":
                    for url in urls {
                        outputs.append(try AudioBleeper.bleep(sourceURL: url, timeRanges: [(start: 0.1, duration: 0.5)], directory: outputDir))
                    }
                default:
                    return
                }

                if !outputs.isEmpty && settings.revealInFinderOnComplete {
                    await MainActor.run { NSWorkspace.shared.activateFileViewerSelecting(outputs) }
                }
            } catch {
                NSLog("[OrbitDrop] Falha em ferramenta %@: %@", itemID, error.localizedDescription)
            }
        }
    }

    private func showQRResults(_ messages: [String]) {
        let alert = NSAlert()
        alert.messageText = messages.isEmpty ? "Nenhum QR Code encontrado" : "QR Code encontrado"
        alert.informativeText = messages.isEmpty ? "A imagem não contém QR code legível." : messages.joined(separator: "\n\n")
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func promptAndProcess(for item: RadialItem) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Selecione arquivos para: \(item.title)"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = (item.id == "action.terminal" || item.id == "action.move")
        openPanel.allowsMultipleSelection = true
        NSApp.activate(ignoringOtherApps: true)
        if openPanel.runModal() == .OK {
            handleFilesDroppedOnItem(item: item, urls: openPanel.urls)
        }
    }

    private func processConversionJob(urls: [URL], targetExtension: String) {
        guard !targetExtension.isEmpty else { return }
        let settings = SettingsManager.shared.settings
        let customDirURL = settings.customOutputDirectory != nil ? URL(fileURLWithPath: settings.customOutputDirectory!) : nil

        Task { [jobQueue] in
            let jobID = await jobQueue.enqueue(
                inputs: urls,
                targetExtension: targetExtension,
                directory: customDirURL
            )

            if let completed = try? await jobQueue.waitForCompletion(jobID: jobID, timeoutSeconds: 60.0),
               !completed.outputURLs.isEmpty,
               settings.revealInFinderOnComplete {
                await MainActor.run {
                    NSWorkspace.shared.activateFileViewerSelecting(completed.outputURLs)
                }
            }
        }
    }
}
