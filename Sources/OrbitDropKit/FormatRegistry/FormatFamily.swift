import Foundation

public enum FormatFamily: String, Sendable, CaseIterable, Equatable, Hashable {
    case image
    case audio
    case video
    case pdf
    case document
    case slides
    case spreadsheet
    case subtitle
    case archive

    public var displayName: String {
        switch self {
        case .image: return "Imagens"
        case .audio: return "Áudio"
        case .video: return "Vídeo"
        case .pdf: return "PDF"
        case .document: return "Documentos"
        case .slides: return "Apresentações"
        case .spreadsheet: return "Planilhas"
        case .subtitle: return "Legendas"
        case .archive: return "Compactados"
        }
    }
}
