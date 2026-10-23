# OrbitDrop — Registro de Decisões de Arquitetura (ADR)

## DEC-001: Swift Package Manager com Módulos Desacoplados
- **Decisão:** Estruturar o projeto com `OrbitDropKit` (biblioteca lógica independente de UI pesada e testável via `swift test`) e `OrbitDropApp` (executável leve macOS).
- **Motivo:** Permite ciclo ultra-rápido de testes TDD no terminal sem inicializar o simulador ou o Xcode GUI completo.
- **Consequência:** Fácil exportação e empacotamento em bundle `.app` com `build_app.sh`.

## DEC-002: AppKit Nativo para Overlay e Menus Radiais
- **Decisão:** Utilizar `NSPanel` borderless com nível `.popUpMenu` e `RadialWheelView` em AppKit puro (CoreGraphics), em vez de SwiftUI puro embutido em NSHostingView.
- **Motivo:** O monitoramento de drag entre aplicativos exige controle milimétrico de coordenadas AppKit, hit-testing imediato durante gestos de arrasto e `NSDraggingDestination`. O SwiftUI introduz camadas adicionais de renderização e perda de eventos finos de drag global.
- **Consequência:** Resposta fluida, zero latência perceptível e baixo consumo de CPU/RAM.

## DEC-003: Pipeline de Escrita com Staging Atômico e Prevenção de Colisão
- **Decisão:** Todo arquivo convertido é gravado primeiramente em um arquivo oculto de trabalho (`.orbitdrop_staging_<UUID>.<ext>`) no mesmo diretório de destino e promovido via `FileManager.moveItem`.
- **Motivo:** Impede geração de arquivos parcialmente corrompidos caso o processo seja interrompido e preserva a regra inegociável de jamais sobrescrever o arquivo original. Nomes colididos recebem sufixos determinísticos (`-converted`, `-converted-2`).

## DEC-004: Fallback Garantido com Drop Zone Flutuante
- **Decisão:** Implementar a `DropZoneWindowController` como fallback acessível e sempre disponível.
- **Motivo:** `NSEvent.addGlobalMonitorForEvents` exige permissão de Acessibilidade (TCC) concedida pelo usuário. Se o usuário recusar ou o ambiente corporativo bloquear o TCC, o aplicativo continua 100% funcional através da drop zone flutuante.

## DEC-005: Ausência Total de Licenciamento e Cotas
- **Decisão:** Não incluir StoreKit, contador de arquivos convertidos, modelos de assinatura ou paywall.
- **Motivo:** O OrbitDrop é concebido como ferramenta de produtividade livre, local e ilimitada, diferenciando-se da limitação de 20 arquivos do concorrente.
