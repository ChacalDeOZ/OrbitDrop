import Foundation

public enum OnboardingStep: Int, Sendable, CaseIterable, Equatable {
    case welcome = 0
    case interactiveDemo = 1
    case permissions = 2
    case firstTest = 3
    case completed = 4

    public var title: String {
        switch self {
        case .welcome: return "Bem-vindo ao OrbitDrop"
        case .interactiveDemo: return "Como Funciona (Gestos)"
        case .permissions: return "Acessibilidade e Privacidade"
        case .firstTest: return "Primeira Conversão"
        case .completed: return "Tudo Pronto!"
        }
    }

    public var description: String {
        switch self {
        case .welcome:
            return "O OrbitDrop é o seu conversor nativo, offline e 100% ilimitado para macOS.\n\nSem trials, sem assinaturas, sem créditos. Suas conversões acontecem direto no seu Mac."
        case .interactiveDemo:
            return "Arraste qualquer arquivo no Finder e toque na tecla desejada para invocar a roda sob o cursor:\n\n• ⇧ Shift: Converte formatos (PNG, JPEG, PDF, MP4...)\n• ⌘ Command: Abre ferramentas de edição e redação\n• ⌃ Control: Dispara ações de arquivo (AirDrop, Copiar, Terminal...)"
        case .permissions:
            return "Para detectar a tecla Shift durante o arrasto de arquivos fora deste app, o macOS exige permissão de Acessibilidade.\n\nSe preferir não autorizar, a Drop Zone flutuante funciona 100% sem nenhuma permissão."
        case .firstTest:
            return "Teste agora mesmo! Arraste uma foto para a Drop Zone flutuante ou teste a roda no cursor pelo ícone na barra de menus."
        case .completed:
            return "O OrbitDrop está ativo na sua barra de menus (topo direito).\n\nVocê pode acessar a Prateleira Flutuante, a Drop Zone ou os Ajustes a qualquer momento."
        }
    }
}
