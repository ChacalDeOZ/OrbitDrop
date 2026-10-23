# Phase 1 Core, Format Registry, Job Queue and 6 File Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar a arquitetura central da Fase 1 do OrbitDrop: catálogo declarativo de formatos (`FormatRegistry`), fila assíncrona desacoplada da UI (`JobQueueActor`), as 6 ações de arquivos de sistema (AirDrop, Float Shelf, Copy, Move, Copy Path, Terminal) e gerenciador de preferências (`SettingsManager`).

**Architecture:** Módulo biblioteca `OrbitDropKit` desacoplado em subsistemas especializados: `FormatRegistry` (grafo dirigido de conversões e cálculo de interseção em lotes), `Jobs` (ator Swift 6 com concorrência limitada e cancelamento cooperativo), `Actions` (despachantes de ações nativas no AppKit) e `Settings` (persistência em `UserDefaults`).

**Tech Stack:** Swift 6.4, macOS 13+, AppKit, CoreGraphics, UniformTypeIdentifiers, ImageIO, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-22-phase-1-core-and-actions-design.md`

## Global Constraints
- Operações ilimitadas desde a instalação: nenhum paywall, licença, cota ou contador de bloqueio comercial.
- 100% offline: sem dependências de rede, telemetria ou SDKs externas.
- Escrita segura: saídas sempre geradas como novas cópias atômicas sem sobrescrita (exceto ação explícita `Move`).
- Concorrência Swift 6 completa (`@MainActor`, `Sendable`, atores dedicados sem data races).

## Review Focus
- Lote misto sem formatos em comum (ex: PNG + TXT) -> lista de destinos vazia sem crash.
- Cancelamento de job na fila durante execução -> remoção garantida de arquivos parciais de staging.
- `MoveAction` com destino no mesmo volume ou entre volumes -> preservação total do original se falhar.
- `TerminalAction` com caminhos contendo espaços ou acentos -> abertura segura sem injeção de shell.
- `CopyAction` no pasteboard -> objetos compatíveis com `NSPasteboard.PasteboardType.fileURL` aceitos pelo Finder.

---

### Task 1: `FormatRegistry` Declarativo e Interseção de Formatos

**Files:**
- Create: `Sources/OrbitDropKit/FormatRegistry/FormatFamily.swift`
- Create: `Sources/OrbitDropKit/FormatRegistry/FormatEdge.swift`
- Create: `Sources/OrbitDropKit/FormatRegistry/FormatRegistry.swift`
- Test: `Tests/OrbitDropKitTests/FormatRegistryTests.swift`

**Interfaces:**
- Consumes: `FileDescriptor`, `RadialItem`
- Produces: `FormatRegistry.shared.availableTargets(for: [FileDescriptor]) -> [RadialItem]`

- [ ] **Step 1: Escrever teste de FormatRegistry**
Criar `Tests/OrbitDropKitTests/FormatRegistryTests.swift` testando:
1. Destinos para 1 arquivo PNG (JPEG, PNG, TIFF, BMP).
2. Interseção para múltiplos arquivos de imagens (PNG + HEIC -> JPEG).
3. Interseção vazia para seleção incompatível (PNG + TXT -> []).

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter FormatRegistryTests`
Expected: FAIL (tipos não existem).

- [ ] **Step 3: Implementar `FormatFamily`, `FormatEdge` e `FormatRegistry`**
Criar catálogo declarativo populado com as arestas validadas da Fase 0 (PNG, JPEG, HEIC, TIFF, BMP).

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter FormatRegistryTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/FormatRegistry/ Tests/OrbitDropKitTests/FormatRegistryTests.swift
git commit -m "feat(core): implement FormatRegistry with multi-file intersection"
```

---

### Task 2: `JobQueueActor` e Execução Assíncrona de Lotes

**Files:**
- Create: `Sources/OrbitDropKit/Jobs/JobStatus.swift`
- Create: `Sources/OrbitDropKit/Jobs/OperationJob.swift`
- Create: `Sources/OrbitDropKit/Jobs/JobQueueActor.swift`
- Test: `Tests/OrbitDropKitTests/JobQueueTests.swift`

**Interfaces:**
- Consumes: `ImagePipeline`, `FileDescriptor`
- Produces: `JobQueueActor.enqueue(inputs:targetExtension:) -> UUID`, `JobQueueActor.cancel(jobID:)`

- [ ] **Step 1: Escrever teste de fila de jobs**
Criar `Tests/OrbitDropKitTests/JobQueueTests.swift` testando:
1. Enfileiramento e execução assíncrona de conversões de imagens sintéticas.
2. Relatório de progresso (0.0 a 1.0).
3. Cancelamento cooperativo de job ativo.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter JobQueueTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `JobStatus`, `OperationJob` e `JobQueueActor`**
Ator Swift 6 com pool de até 4 tarefas concorrentes e canal de notificações de término.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter JobQueueTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Jobs/ Tests/OrbitDropKitTests/JobQueueTests.swift
git commit -m "feat(jobs): implement async JobQueueActor with concurrency control"
```

---

### Task 3: A03 Copy e A05 Copy Path Actions

**Files:**
- Create: `Sources/OrbitDropKit/Actions/ActionType.swift`
- Create: `Sources/OrbitDropKit/Actions/CopyAction.swift`
- Create: `Sources/OrbitDropKit/Actions/CopyPathAction.swift`
- Test: `Tests/OrbitDropKitTests/CopyActionsTests.swift`

**Interfaces:**
- Consumes: `URL`
- Produces: `CopyAction.execute(urls: [URL])`, `CopyPathAction.execute(urls: [URL]) -> String`

- [ ] **Step 1: Escrever teste de ações de cópia**
Criar `Tests/OrbitDropKitTests/CopyActionsTests.swift` testando:
1. `CopyAction`: URLs registradas como objetos `NSURL` no `NSPasteboard.general`.
2. `CopyPathAction`: String com caminhos absolutos UTF-8 separados por quebra de linha.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter CopyActionsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ActionType`, `CopyAction` e `CopyPathAction`**
Manipulação segura de pasteboard com limpeza prévia (`clearContents()`).

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter CopyActionsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Actions/CopyAction.swift Sources/OrbitDropKit/Actions/CopyPathAction.swift Sources/OrbitDropKit/Actions/ActionType.swift Tests/OrbitDropKitTests/CopyActionsTests.swift
git commit -m "feat(actions): implement Copy and CopyPath actions"
```

---

### Task 4: A06 Terminal Action e A04 Move Action

**Files:**
- Create: `Sources/OrbitDropKit/Actions/TerminalAction.swift`
- Create: `Sources/OrbitDropKit/Actions/MoveAction.swift`
- Test: `Tests/OrbitDropKitTests/TerminalAndMoveTests.swift`

**Interfaces:**
- Consumes: `URL`, `OutputWriter`
- Produces: `TerminalAction.targetDirectory(for: URL) -> URL`, `MoveAction.move(files:to:) throws -> [URL]`

- [ ] **Step 1: Escrever teste de Terminal e Move**
Criar `Tests/OrbitDropKitTests/TerminalAndMoveTests.swift` testando:
1. `targetDirectory`: para pasta retorna ela mesma; para arquivo retorna seu pai.
2. `MoveAction`: movimentação segura de arquivos locais resolvendo colisões.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter TerminalAndMoveTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `TerminalAction` e `MoveAction`**
Implementar resolução de diretório para abertura do Terminal e rotina de movimentação com `FileManager.default.moveItem`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter TerminalAndMoveTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Actions/TerminalAction.swift Sources/OrbitDropKit/Actions/MoveAction.swift Tests/OrbitDropKitTests/TerminalAndMoveTests.swift
git commit -m "feat(actions): implement Terminal and Move file actions"
```

---

### Task 5: A01 AirDrop e A02 Float Shelf Controller

**Files:**
- Create: `Sources/OrbitDropKit/Actions/AirDropAction.swift`
- Create: `Sources/OrbitDropKit/Actions/FloatShelfController.swift`
- Create: `Sources/OrbitDropKit/Actions/ActionDispatcher.swift`
- Test: `Tests/OrbitDropKitTests/ActionDispatcherTests.swift`

**Interfaces:**
- Consumes: `ActionType`, `[URL]`
- Produces: `ActionDispatcher.dispatch(action:files:)`, `FloatShelfController.add(files:)`

- [ ] **Step 1: Escrever teste do ActionDispatcher**
Criar `Tests/OrbitDropKitTests/ActionDispatcherTests.swift` testando o roteamento correto de cada `ActionType`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter ActionDispatcherTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `AirDropAction`, `FloatShelfController` e `ActionDispatcher`**
1. `AirDropAction`: invocação de `NSSharingService(named: .sendViaAirDrop)`.
2. `FloatShelfController`: janela flutuante com coleção de arquivos e suporte a drag-out.
3. `ActionDispatcher`: fachada unificada para despacho de ações.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter ActionDispatcherTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Actions/ Tests/OrbitDropKitTests/ActionDispatcherTests.swift
git commit -m "feat(actions): implement AirDrop, FloatShelf and ActionDispatcher"
```

---

### Task 6: `SettingsManager` e Persistência de Preferências

**Files:**
- Create: `Sources/OrbitDropKit/Settings/AppSettings.swift`
- Create: `Sources/OrbitDropKit/Settings/SettingsManager.swift`
- Create: `Sources/OrbitDropKit/Settings/SettingsWindowController.swift`
- Test: `Tests/OrbitDropKitTests/SettingsTests.swift`

**Interfaces:**
- Consumes: `UserDefaults`
- Produces: `SettingsManager.shared.settings: AppSettings`

- [ ] **Step 1: Escrever teste de configurações**
Criar `Tests/OrbitDropKitTests/SettingsTests.swift` testando persistência e valores padrão de `AppSettings`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter SettingsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `AppSettings`, `SettingsManager` e `SettingsWindowController`**
Estrutura codificável de preferências, singleton de acesso e janela de ajustes nativa.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter SettingsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Settings/ Tests/OrbitDropKitTests/SettingsTests.swift
git commit -m "feat(settings): implement SettingsManager and SettingsWindowController"
```

---

### Task 7: Integração Completa no `AppDelegate`, Recompilação e Validação

**Files:**
- Modify: `Sources/OrbitDropApp/AppDelegate.swift`
- Modify: `Sources/OrbitDropKit/UI/StatusItemController.swift`
- Modify: `FEATURE_MATRIX.md`
- Modify: `TASKS.md`

- [ ] **Step 1: Integrar `FormatRegistry`, `JobQueueActor` e `ActionDispatcher` no `AppDelegate`**
1. Atualizar menu radial dinamicamente com base em arquivos selecionados usando `FormatRegistry`.
2. Encaminhar drops de conversão para o `JobQueueActor`.
3. Encaminhar modo `.actions` para o `ActionDispatcher`.
4. Conectar opções de abrir Ajustes e Prateleira Flutuante ao `StatusItemController`.

- [ ] **Step 2: Executar suite completa de testes**
Run: `swift test`
Expected: PASS com 100% dos testes da Fase 0 e Fase 1.

- [ ] **Step 3: Recompilar e empacotar bundle release**
Run: `./Scripts/build_app.sh`
Expected: Bundle `build/OrbitDrop.app` gerado e assinado com sucesso.

- [ ] **Step 4: Atualizar `FEATURE_MATRIX.md` e `TASKS.md`**
Registrar a conclusão integral das tarefas da Fase 1.

- [ ] **Step 5: Commit final da Fase 1**
```bash
git add Sources/OrbitDropApp/ Sources/OrbitDropKit/UI/ FEATURE_MATRIX.md TASKS.md
git commit -m "feat(phase-1): integrate FormatRegistry, JobQueue and 6 actions into OrbitDropApp"
```
