# Phase 0 Feasibility and Functional Prototype Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Construir a base modular do OrbitDrop em Swift/AppKit, provando a viabilidade de detecção de arrasto global, menu radial sem foco, conversão ImageIO (PNG/HEIC → JPEG) sem sobrescrita e garantia de operações ilimitadas e offline.

**Architecture:** Pacote Swift com módulo biblioteca `OrbitDropKit` e executável `OrbitDropApp`. Modelos desacoplados, geometria radial desacoplada de UI, escrita atômica com `OutputWriter`, monitor de eventos com fallback gracioso para janela flutuante quando sem permissão TCC.

**Tech Stack:** Swift 6.4, macOS 27+ (compatível com macOS 13+), AppKit, CoreGraphics, ImageIO, UniformTypeIdentifiers, XCTest.

---

### Task 1: Package.swift e Modelos Fundamentais

**Files:**
- Create: `Package.swift`
- Create: `Sources/OrbitDropKit/Models/FileDescriptor.swift`
- Create: `Sources/OrbitDropKit/Models/DragPayload.swift`
- Create: `Sources/OrbitDropKit/Models/WheelMode.swift`
- Create: `Sources/OrbitDropKit/Models/RadialItem.swift`
- Test: `Tests/OrbitDropKitTests/ModelsTests.swift`

**Step 1: Escrever teste de modelos**
Criar `Tests/OrbitDropKitTests/ModelsTests.swift` validando instanciação, conformidade Sendable, propriedades de `FileDescriptor`, `WheelMode` e `RadialItem`.

**Step 2: Rodar teste para verificar falha**
Executar: `swift test --filter ModelsTests` (deve falhar por falta de `Package.swift` e tipos).

**Step 3: Implementar `Package.swift` e tipos em `Sources/OrbitDropKit/Models/`**
- Configurar targets: `OrbitDropKit`, `OrbitDropApp`, `OrbitDropKitTests`.
- Implementar `FileDescriptor` com detecção de `UTType` e tamanho.
- Implementar `DragPayload` com array de `FileDescriptor`.
- Implementar `WheelMode` (`.convert`, `.tools`, `.actions`, com tecla modificadora correspondente).
- Implementar `RadialItem` (id, título, ícone de sistema, extensão de destino, disponibilidade).

**Step 4: Rodar teste para verificar sucesso**
Executar: `swift test --filter ModelsTests` (deve passar 100%).

**Step 5: Commit**
`git add Package.swift Sources/OrbitDropKit/Models/ Tests/OrbitDropKitTests/ModelsTests.swift && git commit -m "feat(core): setup package and core models"`

---

### Task 2: Geometria Radial e Hit-Testing

**Files:**
- Create: `Sources/OrbitDropKit/Radial/RadialGeometry.swift`
- Test: `Tests/OrbitDropKitTests/RadialGeometryTests.swift`

**Step 1: Escrever teste de geometria radial**
Criar `Tests/OrbitDropKitTests/RadialGeometryTests.swift` testando:
- Ângulo de 0° a 360° a partir de vetor cartesiano.
- Rejeição na zona morta central (raio < 28 pt).
- Identificação correta de setor para 3, 4 e 6 opções.
- Clamping de centro da janela para evitar transbordamento nas bordas da tela.

**Step 2: Rodar teste para verificar falha**
Executar: `swift test --filter RadialGeometryTests` (deve falhar: tipo `RadialGeometry` não existe).

**Step 3: Implementar `RadialGeometry`**
Criar cálculos estáticos puros:
- `angle(from center: CGPoint, to point: CGPoint) -> CGFloat`
- `sectorIndex(at point: CGPoint, center: CGPoint, sectorCount: Int, innerRadius: CGFloat, outerRadius: CGFloat) -> Int?`
- `clampedCenter(cursor: CGPoint, screenSize: CGSize, wheelRadius: CGFloat, margin: CGFloat) -> CGPoint`
- `sectorMidPoint(sectorIndex: Int, sectorCount: Int, center: CGPoint, radius: CGFloat) -> CGPoint`

**Step 4: Rodar teste para verificar sucesso**
Executar: `swift test --filter RadialGeometryTests` (deve passar 100%).

**Step 5: Commit**
`git add Sources/OrbitDropKit/Radial/RadialGeometry.swift Tests/OrbitDropKitTests/RadialGeometryTests.swift && git commit -m "feat(radial): implement radial geometry and hit-testing"`

---

### Task 3: OutputWriter Seguro e Resolução de Colisões

**Files:**
- Create: `Sources/OrbitDropKit/FileAccess/OutputWriter.swift`
- Test: `Tests/OrbitDropKitTests/OutputWriterTests.swift`

**Step 1: Escrever teste de escrita segura**
Criar `Tests/OrbitDropKitTests/OutputWriterTests.swift` testando:
- Geração de nome com sufixo: `foto.png` → `foto-converted.jpg`.
- Resolução de colisão se destino já existe: `foto-converted.jpg` existente → `foto-converted-2.jpg`.
- Escrita atômica: arquivo de trabalho é temporário e promovido sem truncar ou apagar original.
- Tratamento de erro com limpeza garantida de temporários em falha.

**Step 2: Rodar teste para verificar falha**
Executar: `swift test --filter OutputWriterTests` (deve falhar: `OutputWriter` não definido).

**Step 3: Implementar `OutputWriter`**
Criar `OutputWriter` com:
- `destinationURL(for sourceURL: URL, targetExtension: String, directory: URL?) -> URL`
- `withStagingFile(targetURL: URL, block: (URL) throws -> Void) throws -> URL`
- Garantia de atomização e remoção de arquivo temporário via `defer`.

**Step 4: Rodar teste para verificar sucesso**
Executar: `swift test --filter OutputWriterTests` (deve passar 100%).

**Step 5: Commit**
`git add Sources/OrbitDropKit/FileAccess/OutputWriter.swift Tests/OrbitDropKitTests/OutputWriterTests.swift && git commit -m "feat(storage): implement safe atomic OutputWriter"`

---

### Task 4: Pipeline de Imagem Local (ImageIO)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/ImagePipeline.swift`
- Test: `Tests/OrbitDropKitTests/ImagePipelineTests.swift`

**Step 1: Escrever teste de conversão de imagem**
Criar `Tests/OrbitDropKitTests/ImagePipelineTests.swift`:
- Criar fixture PNG sintético em memória (RGBA 64x64) e salvar em diretório temporário.
- Executar `ImagePipeline.convert(sourceURL: targetExtension: "jpg", compressionQuality: 0.85)`.
- Verificar se JPEG de saída existe, tamanho > 0, cabeçalho `0xFFD8` e decodificação via `CGImageSource` bem-sucedida.
- Verificar que PNG original permaneceu inalterado.

**Step 2: Rodar teste para verificar falha**
Executar: `swift test --filter ImagePipelineTests` (deve falhar).

**Step 3: Implementar `ImagePipeline`**
- Uso nativo de `CGImageSourceCreateWithURL` e `CGImageDestinationCreateWithURL`.
- Suporte a PNG, JPEG, TIFF, BMP, HEIC como entrada.
- Exportação para JPEG/PNG com preservação de propriedades e espaço de cores.
- Integração com `OutputWriter` para escrita atômica.

**Step 4: Rodar teste para verificar sucesso**
Executar: `swift test --filter ImagePipelineTests` (deve passar 100%).

**Step 5: Commit**
`git add Sources/OrbitDropKit/Engines/ImagePipeline.swift Tests/OrbitDropKitTests/ImagePipelineTests.swift && git commit -m "feat(engine): implement native ImageIO pipeline"`

---

### Task 5: Garantia e Teste de Uso Ilimitado

**Files:**
- Test: `Tests/OrbitDropKitTests/UnlimitedUsageTests.swift`

**Step 1: Escrever teste de estresse de cota ilimitada**
Criar `Tests/OrbitDropKitTests/UnlimitedUsageTests.swift`:
- Executar em loop conversão de 105 arquivos sucessivos.
- Validar explicitamente que a 20ª, 21ª e 101ª conversão concluem com status `success`.
- Validar que nenhuma exceção de cota, licença ou necessidade de rede é disparada.

**Step 2: Rodar teste para verificar sucesso imediato**
Executar: `swift test --filter UnlimitedUsageTests` (deve passar, confirmando ausência estrutural de paywall).

**Step 3: Commit**
`git add Tests/OrbitDropKitTests/UnlimitedUsageTests.swift && git commit -m "test(compliance): assert unlimited offline operations without trial"`

---

### Task 6: Detecção de Permissão TCC e Monitor de Intenção de Arrasto

**Files:**
- Create: `Sources/OrbitDropKit/Drag/AccessibilityChecker.swift`
- Create: `Sources/OrbitDropKit/Drag/DragIntentDetector.swift`
- Test: `Tests/OrbitDropKitTests/DragIntentTests.swift`

**Step 1: Escrever teste para DragIntentDetector**
Criar `Tests/OrbitDropKitTests/DragIntentTests.swift` testando parsing de modificadores (`NSEvent.ModifierFlags`), estado inicial e callbacks de intenção.

**Step 2: Implementar `AccessibilityChecker` e `DragIntentDetector`**
- `AccessibilityChecker.isProcessTrusted() -> Bool` e `openAccessibilityPreferences()`.
- `DragIntentDetector`: gerencia monitor global (`addGlobalMonitorForEvents`) e monitor local (`addLocalMonitorForEvents`).
- Publica callbacks `onDragIntentDetected(WheelMode, CGPoint)` e `onDragCancelled`.

**Step 3: Rodar teste para verificar sucesso**
Executar: `swift test --filter DragIntentTests` (deve passar 100%).

**Step 4: Commit**
`git add Sources/OrbitDropKit/Drag/ Tests/OrbitDropKitTests/DragIntentTests.swift && git commit -m "feat(drag): implement accessibility checker and drag intent detector"`

---

### Task 7: Interface do Usuário (Overlay Radial, Painel e DropZone Fallback)

**Files:**
- Create: `Sources/OrbitDropKit/UI/RadialSectorView.swift`
- Create: `Sources/OrbitDropKit/UI/RadialWheelView.swift`
- Create: `Sources/OrbitDropKit/UI/RadialPanelController.swift`
- Create: `Sources/OrbitDropKit/UI/DropZoneWindowController.swift`
- Create: `Sources/OrbitDropKit/UI/StatusItemController.swift`

**Step 1: Implementar visual dos setores e roda (`RadialSectorView`, `RadialWheelView`)**
- Renderização em CoreGraphics/AppKit de arcos circulares, ícones SF Symbols e rótulos de extensão (ex: `.jpg`, `.png`, `.webp`).
- Destaque visual (hover state) quando o cursor estiver no setor.
- `NSDraggingDestination`: `draggingEntered`, `draggingUpdated`, `performDragOperation`.

**Step 2: Implementar `RadialPanelController`**
- `NSPanel` configurado como `.nonactivatingPanel`, nível `.popUpMenu` ou `.floating`, `isOpaque = false`, `backgroundColor = .clear`.
- Métodos `show(at:mode:items:)` e `hide()`.

**Step 3: Implementar `DropZoneWindowController`**
- Janela flutuante compacta para fallback garantido quando acessibilidade estiver desativada.
- Aceita drops diretamente e converte para JPEG com um clique.

**Step 4: Implementar `StatusItemController`**
- Ícone na barra de menus com menu nativo: "OrbitDrop Ativo", "Abrir Drop Zone Flutuante", "Ajustes de Acessibilidade", "Sobre OrbitDrop", "Encerrar".

**Step 5: Compilar e validar**
Executar: `swift build` (deve compilar todos os componentes UI com sucesso).

**Step 6: Commit**
`git add Sources/OrbitDropKit/UI/ && git commit -m "feat(ui): implement radial panel, drop zone fallback and status item"`

---

### Task 8: Ponto de Entrada da Aplicação e Branding

**Files:**
- Create: `Sources/OrbitDropApp/AppBranding.swift`
- Create: `Sources/OrbitDropApp/AppDelegate.swift`
- Create: `Sources/OrbitDropApp/main.swift`
- Create: `Scripts/build_app.sh`

**Step 1: Implementar `AppBranding.swift`**
Definir nomes, versão, marca `OrbitDrop`, sem referências a marcas de terceiros.

**Step 2: Implementar `AppDelegate.swift` e `main.swift`**
- Inicialização do `NSApplication`.
- Configuração do `StatusItemController`, `DragIntentDetector`, `RadialPanelController` e `ImagePipeline`.
- Tratamento de drops com notificação no sistema e reveal no Finder.

**Step 3: Criar script de empacotamento `Scripts/build_app.sh`**
- Compilar binário release via `swift build -c release`.
- Criar bundle padrão macOS `OrbitDrop.app/Contents/MacOS/OrbitDropApp` com `Info.plist` adequado (`LSUIElement = true` para menu bar app).

**Step 4: Tornar script executável e testar build do app**
Executar: `chmod +x Scripts/build_app.sh && ./Scripts/build_app.sh`

**Step 5: Commit**
`git add Sources/OrbitDropApp/ Scripts/build_app.sh && git commit -m "feat(app): implement app entrypoint, branding and build script"`

---

### Task 9: Documentação e Matriz de Viabilidade da Fase 0

**Files:**
- Create: `PLAN.md`
- Create: `TASKS.md`
- Create: `DECISIONS.md`
- Create: `FEATURE_MATRIX.md`
- Create: `THIRD_PARTY_NOTICES.md`
- Create: `Documentation/POC_FINDINGS.md`
- Create: `README.md`

**Step 1: Escrever arquivos de documentação com a matriz de resultados comprovados**
- `PLAN.md`: Roadmap geral das Fases 0 a 5.
- `TASKS.md`: Checklist executável.
- `DECISIONS.md`: Registro de decisões técnicas tomadas (ex.: AppKit puro para overlay, fallback para TCC, ImageIO nativo).
- `FEATURE_MATRIX.md`: Registro real de formatos suportados e testados.
- `THIRD_PARTY_NOTICES.md`: Relatório de dependências (0 dependências externas de terceiros; 100% Apple SDK).
- `Documentation/POC_FINDINGS.md`: Matriz de viabilidade de drag em macOS real.
- `README.md`: Instruções de compilação, execução e testes.

**Step 2: Executar suite completa de testes e registrar saída**
Executar: `swift test`

**Step 3: Commit**
`git add PLAN.md TASKS.md DECISIONS.md FEATURE_MATRIX.md THIRD_PARTY_NOTICES.md Documentation/ README.md && git commit -m "docs: add Phase 0 tracking documents and POC findings"`

---
