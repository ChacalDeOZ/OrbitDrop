# Especificação Técnica — OrbitDrop: Fase 0 (Estudo de Viabilidade e Protótipo Funcional)

**Data:** 2026-10-22  
**Status:** Aprovado para Planejamento  
**Objetivo:** Validar tecnicamente a interceptação de arrasto global no macOS, a sobreposição radial (radial overlay) sem perda de foco, a conversão nativa local e a garantia de operações ilimitadas e offline.

---

## 1. Visão Geral e Requisitos

### 1.1 Escopo da Fase 0
- Criação de pacote Swift modular (`Package.swift`) contendo o executável macOS (`OrbitDropApp`) e o framework principal (`OrbitDropKit`).
- Presença de item permanente na barra de menus (`NSStatusItem`).
- Detecção de modificadores globais (`Shift`, `Command`, `Control`) durante arrasto de arquivos.
- Exibição de painel flutuante sem ativação (`NSPanel` com `styleMask: .nonactivatingPanel`, nível flutuante) ancorado nas coordenadas globais do cursor.
- Interface radial com setores hit-testáveis para conversão.
- Pipeline real de transformação de imagens via `ImageIO` (PNG/HEIC para JPEG com qualidade configurável).
- `OutputWriter` seguro: saída gerada ao lado do original com padrão `<nome>-converted.<ext>`, resolução atômica de colisões e preservação estrita do arquivo de origem.
- Fallback acessível: janela flutuante `DropZoneWindow` para uso quando permissões de monitoramento global (TCC/Accessibility) não forem concedidas.
- **Uso ilimitado:** nenhuma restrição por cota, contador de trial, verificação de licença ou dependência de rede.

---

## 2. Arquitetura dos Módulos

```text
OrbitDrop/
├── Package.swift
├── Sources/
│   ├── OrbitDropApp/
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   └── AppBranding.swift
│   └── OrbitDropKit/
│       ├── Models/
│       │   ├── FileDescriptor.swift
│       │   ├── DragPayload.swift
│       │   ├── WheelMode.swift
│       │   └── RadialItem.swift
│       ├── Drag/
│       │   ├── DragIntentDetector.swift
│       │   ├── AccessibilityChecker.swift
│       │   └── DropDestinationView.swift
│       ├── Radial/
│       │   ├── RadialGeometry.swift
│       │   ├── RadialSector.swift
│       │   └── RadialPanelController.swift
│       ├── Engines/
│       │   └── ImagePipeline.swift
│       ├── FileAccess/
│       │   └── OutputWriter.swift
│       └── UI/
│           ├── StatusItemController.swift
│           └── DropZoneWindowController.swift
└── Tests/
    └── OrbitDropKitTests/
        ├── RadialGeometryTests.swift
        ├── OutputWriterTests.swift
        ├── ImagePipelineTests.swift
        └── UnlimitedUsageTests.swift
```

---

## 3. Especificação dos Componentes

### 3.1 `Models`
- `FileDescriptor`: armazena `url`, `displayName`, `fileSize`, `contentType` (`UTType`) e `isFolder`.
- `DragPayload`: conjunto de `[FileDescriptor]`, timestamp do início do gesto e origem.
- `WheelMode`: enumeração `.convert` (Shift), `.tools` (Command), `.actions` (Control).
- `RadialItem`: identificador, título, ícone de sistema, destino e status de disponibilidade.

### 3.2 `DragIntentDetector`
- Utiliza `NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .leftMouseDragged])`.
- Monitora se `Shift` está ativo enquanto o botão esquerdo do mouse permanece pressionado.
- Verifica autorização TCC via `AXIsProcessTrustedWithOptions`. Se ausente, não bloqueia o app: emite log e direciona para a zona de fallback.

### 3.3 `RadialPanelController` & `RadialGeometry`
- Janela flutuante (`NSPanel` transparente, borderless, sem sombra de sistema, `level = .popUpMenu`).
- Posicionamento com origem no cursor, ajustando dinamicamente coordenadas próximas às bordas da tela.
- Hit testing angular por setor radial: raio interno (zona morta central de 28 pt), raio externo (90 pt), setores divididos igualmente conforme contagem de opções.
- Receptor de drop nativo (`NSDraggingDestination`) com registro de tipos `NSPasteboard.PasteboardType.fileURL`.

### 3.4 `ImagePipeline`
- Entrada: URL de arquivo PNG ou HEIC válido.
- Processamento: leitura segura via `CGImageSourceCreateWithURL`, renderização e exportação para JPEG via `CGImageDestinationCreateWithData` com fator de compressão 0.85.
- Validação: confirma existência de bytes, cabeçalho JPEG e capacidade de decodificação antes de finalizar.

### 3.5 `OutputWriter`
- Garante que a escrita ocorre em diretório temporário isolado.
- Resolve nomes no destino final evitando qualquer sobrescrita: `arquivo-converted.jpg`, `arquivo-converted-2.jpg`.
- Move atômico do temporário para o destino final via `FileManager.default.moveItem`.

### 3.6 `DropZoneWindowController`
- Janela flutuante compacta, sempre visível opcionalmente, permitindo arrasto manual do Finder para o aplicativo sem requerer eventos globais do sistema.

---

## 4. Testes Automatizados e Critérios de Aceite

1. **`RadialGeometryTests`**: validação de cálculo de ângulos (0° a 360°), distribuição equitativa de 3, 4 e 5 setores, e rejeição de toques no raio morto central.
2. **`OutputWriterTests`**: validação de geração de nomes sem colisão e garantia de não-destruição do arquivo de origem.
3. **`ImagePipelineTests`**: geração programática de bitmap PNG sintético com cores definidas, conversão para JPEG e verificação de integridade de dimensões e decodificação do arquivo gerado.
4. **`UnlimitedUsageTests`**: simulação de 21 e 101 conversões sequenciais confirmando sucesso integral e ausência de bloqueios de cota ou paywall.
5. **Critério de Aceite da Fase 0**: build executável funcional compila via `swift build`, suite de testes passa via `swift test`, e manual QA demonstra abertura de overlay e geração de JPEG no macOS.
