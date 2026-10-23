import Foundation
import UniformTypeIdentifiers

public enum ToolRegistry: Sendable {
    /// Retorna a lista de ferramentas contextuais aplicáveis estritamente aos arquivos fornecidos.
    public static func availableTools(for files: [FileDescriptor]) -> [RadialItem] {
        guard !files.isEmpty else {
            return defaultTools()
        }

        let isAllImages = files.allSatisfy { $0.contentType.conforms(to: .image) && !$0.isDirectory }
        let isAllVideos = files.allSatisfy { ($0.contentType.conforms(to: .movie) || $0.contentType.conforms(to: .video)) && !$0.isDirectory }
        let isAllAudio = files.allSatisfy { $0.contentType.conforms(to: .audio) && !$0.isDirectory }
        let isAllPDF = files.allSatisfy { $0.contentType.conforms(to: .pdf) && !$0.isDirectory }

        if isAllImages {
            var tools: [RadialItem] = [
                RadialItem(id: "tool.compress", title: "Comprimir", iconName: "arrow.down.circle", targetExtension: "jpg"),
                RadialItem(id: "tool.metadata", title: "Metadados", iconName: "info.circle", targetExtension: ""),
                RadialItem(id: "tool.ocr", title: "OCR / Texto", iconName: "text.viewfinder", targetExtension: "md"),
                RadialItem(id: "tool.adjust", title: "Ajustar", iconName: "slider.horizontal.3", targetExtension: ""),
                RadialItem(id: "tool.crop", title: "Cortar", iconName: "crop", targetExtension: ""),
                RadialItem(id: "tool.background", title: "Fundo", iconName: "rectangle.inset.filled", targetExtension: ""),
                RadialItem(id: "tool.redact", title: "Redigir", iconName: "eye.slash", targetExtension: ""),
                RadialItem(id: "tool.annotate", title: "Anotar", iconName: "pencil.tip", targetExtension: ""),
                RadialItem(id: "tool.qr", title: "Ler QR", iconName: "qrcode.viewfinder", targetExtension: "")
            ]
            if files.count > 1 {
                tools.insert(RadialItem(id: "tool.pdf", title: "Fotos para PDF", iconName: "doc.richtext", targetExtension: ""), at: 0)
                tools.append(RadialItem(id: "tool.collage", title: "Colagem", iconName: "square.grid.2x2", targetExtension: ""))
            }
            return tools
        }

        if isAllVideos {
            var tools: [RadialItem] = [
                RadialItem(id: "tool.video.trim", title: "Cortar Vídeo", iconName: "film", targetExtension: ""),
                RadialItem(id: "tool.video.crop", title: "Crop Vídeo", iconName: "crop", targetExtension: ""),
                RadialItem(id: "tool.video.speed", title: "Acelerar", iconName: "speedometer", targetExtension: ""),
                RadialItem(id: "tool.video.frames", title: "Salvar Frames", iconName: "photo.on.rectangle", targetExtension: ""),
                RadialItem(id: "tool.video.split", title: "Dividir", iconName: "scissors", targetExtension: ""),
                RadialItem(id: "tool.video.redact", title: "Redigir Vídeo", iconName: "eye.slash", targetExtension: "")
            ]
            if files.count > 1 {
                tools.append(RadialItem(id: "tool.video.join", title: "Juntar Vídeos", iconName: "film.stack", targetExtension: ""))
            }
            return tools
        }

        if isAllAudio {
            return [
                RadialItem(id: "tool.audio.normalize", title: "Normalizar", iconName: "waveform", targetExtension: ""),
                RadialItem(id: "tool.audio.visualizer", title: "Visualizer", iconName: "waveform.path.ecg", targetExtension: ""),
                RadialItem(id: "tool.audio.trim", title: "Cortar Áudio", iconName: "waveform.badge.minus", targetExtension: ""),
                RadialItem(id: "tool.audio.channels", title: "Canais", iconName: "speaker.wave.2", targetExtension: ""),
                RadialItem(id: "tool.audio.bleep", title: "Bleep Áudio", iconName: "speaker.slash", targetExtension: "")
            ]
        }

        if isAllPDF {
            var tools: [RadialItem] = [
                RadialItem(id: "tool.ocr", title: "OCR / Markdown", iconName: "text.viewfinder", targetExtension: "md"),
                RadialItem(id: "tool.pdf.split", title: "Dividir PDF", iconName: "scissors", targetExtension: ""),
                RadialItem(id: "tool.pdf.organize", title: "Organizar Páginas", iconName: "arrow.up.and.down.and.arrow.left.and.right", targetExtension: "")
            ]
            if files.count > 1 {
                tools.insert(RadialItem(id: "tool.pdf.merge", title: "Juntar PDFs", iconName: "doc.on.doc", targetExtension: ""), at: 0)
            }
            return tools
        }

        // Lotes mistos ou arquivos genéricos
        return [
            RadialItem(id: "tool.compress", title: "Comprimir", iconName: "arrow.down.circle", targetExtension: "zip"),
            RadialItem(id: "tool.ocr", title: "OCR / Texto", iconName: "text.viewfinder", targetExtension: "md"),
            RadialItem(id: "tool.metadata", title: "Metadados", iconName: "info.circle", targetExtension: "")
        ]
    }

    public static func defaultTools() -> [RadialItem] {
        [
            RadialItem(id: "tool.compress", title: "Comprimir", iconName: "arrow.down.circle", targetExtension: "jpg"),
            RadialItem(id: "tool.metadata", title: "Metadados", iconName: "info.circle", targetExtension: ""),
            RadialItem(id: "tool.ocr", title: "OCR / Texto", iconName: "text.viewfinder", targetExtension: "md"),
            RadialItem(id: "tool.adjust", title: "Ajustar", iconName: "slider.horizontal.3", targetExtension: ""),
            RadialItem(id: "tool.crop", title: "Cortar", iconName: "crop", targetExtension: ""),
            RadialItem(id: "tool.background", title: "Fundo", iconName: "rectangle.inset.filled", targetExtension: ""),
            RadialItem(id: "tool.redact", title: "Redigir", iconName: "eye.slash", targetExtension: ""),
            RadialItem(id: "tool.qr", title: "Ler QR", iconName: "qrcode.viewfinder", targetExtension: "")
        ]
    }
}
