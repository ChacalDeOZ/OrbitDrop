# Especificação Técnica — OrbitDrop: Fase 1 (Core, Catálogo Declarativo, Fila Assíncrona e 6 Ações)

**Data:** 2026-10-22  
**Status:** Aprovado para Planejamento  
**Objetivo:** Implementar o núcleo de orquestração de formatos (`FormatRegistry`), gerenciamento de concorrência e tarefas em background (`JobQueueActor`), as 6 ações de arquivo fundamentais (AirDrop, Float Shelf, Copy, Move, Copy Path, Terminal) e o gerenciador de configurações (`SettingsManager`).

---

## 1. Visão Geral e Requisitos

### 1.1 Escopo da Fase 1
1. **`FormatRegistry` declarativo:**
   - Registro estruturado com famílias (`image, audio, video, pdf, document, slides, spreadsheet, subtitle, archive`).
   - Cada aresta mapeia `(sourceUTType, targetExtension)` para um motor real com metadados: `supportsBatch`, `needsOptions`, `qualityPreset`.
   - Cálculo automático de destinos comuns para seleções heterogêneas de arquivos.
   - Atualização dinâmica do menu radial com base nos arquivos atualmente selecionados.

2. **Fila de Jobs Assíncrona (`JobQueueActor`):**
   - Ator Swift 6 para processamento concorrente seguro sem data races.
   - Concorrência limitada (padrão 4 jobs simultâneos para I/O e processamento de imagem).
   - Cancelamento cooperativo e suporte a progresso por item e agregado.
   - Desacoplamento da thread principal (`@MainActor`), evitando qualquer travamento da interface durante processamentos de lotes.

3. **As Seis Ações de Arquivo (`ActionDispatcher`):**
   - **A01 AirDrop:** Disparo de `NSSharingService(named: .sendViaAirDrop)` com arquivos/pastas locais válidos.
   - **A02 Float Shelf:** Janela flutuante `FloatShelfController` com suporte a drag-in e drag-out para retenção temporária de arquivos entre janelas e Spaces.
   - **A03 Copy:** Preenchimento de `NSPasteboard.general` com URLs de arquivo (`NSFilenamesPboardType` e `.fileURL`) para colar no Finder (`Cmd+V`).
   - **A04 Move:** Diálogo com `NSOpenPanel` para escolha de pasta de destino, movimentação atômica com preservação e tratamento de cross-volume (copy + verify + delete com confirmação).
   - **A05 Copy Path:** Cópia de caminhos absolutos UTF-8 no clipboard (1 por linha).
   - **A06 Terminal:** Abertura da pasta (ou diretório pai do arquivo) no Terminal padrão do macOS ou iTerm2 se configurado.

4. **Gerenciador de Preferências (`SettingsManager`):**
   - Pasta de destino personalizada ou ao lado do original (padrão).
   - Política de colisão de nomes.
   - Limite de concorrência.
   - Preferência de terminal (Terminal vs. iTerm2).

5. **Uso Ilimitado:** Nenhuma restrição de uso, contador de operações ou tela de pagamento em qualquer conversão ou ação.

---

## 2. Arquitetura dos Módulos

```text
Sources/OrbitDropKit/
├── FormatRegistry/
│   ├── FormatFamily.swift
│   ├── FormatEdge.swift
│   └── FormatRegistry.swift
├── Jobs/
│   ├── OperationJob.swift
│   ├── JobStatus.swift
│   └── JobQueueActor.swift
├── Actions/
│   ├── ActionType.swift
│   ├── ActionDispatcher.swift
│   ├── AirDropAction.swift
│   ├── FloatShelfController.swift
│   ├── CopyAction.swift
│   ├── MoveAction.swift
│   ├── CopyPathAction.swift
│   └── TerminalAction.swift
└── Settings/
    ├── AppSettings.swift
    ├── SettingsManager.swift
    └── SettingsWindowController.swift
```

---

## 3. Especificação dos Componentes

### 3.1 `FormatRegistry`
- Armazena conjunto de `FormatEdge`:
  - `sourceType: UTType`
  - `targetExtension: String`
  - `targetType: UTType`
  - `family: FormatFamily`
  - `supportsBatch: Bool`
- Método `availableTargets(for files: [FileDescriptor]) -> [RadialItem]` que calcula a interseção dos destinos válidos para todos os arquivos fornecidos.

### 3.2 `JobQueueActor`
- Mantém lista de `OperationJob`: id, URLs de entrada, extensão de destino, status (`queued, running, completed, failed, cancelled`), progresso de 0.0 a 1.0.
- Executa até `maxConcurrentJobs` paralelamente via `withTaskGroup`.
- Emite callbacks thread-safe para o `AppDelegate` notificar o usuário e revelar no Finder ao término.

### 3.3 Ações de Arquivo
- Despachadas sob demanda quando o usuário aciona o modo `Actions` (`Control` no drag) ou via atalhos do menu bar.
- Operam de forma independente do pipeline de conversão.

---

## 4. Testes Automatizados e Critérios de Aceite
1. **`FormatRegistryTests`**:
   - Registro de rotas válidas para PNG, JPEG, HEIC, TIFF, BMP.
   - Interseção correta para seleção mista: PNG + HEIC → destino JPEG retornado; PNG + TXT → lista vazia (sem destinos comuns).
2. **`JobQueueTests`**:
   - Processamento de lote em fila assíncrona.
   - Cancelamento de job no meio da execução.
   - Progresso agregado e por arquivo.
3. **`ActionsTests`**:
   - Teste de `CopyAction`: URLs corretas no `NSPasteboard`.
   - Teste de `CopyPathAction`: Caminhos UTF-8 formatados por linha.
   - Teste de `TerminalAction`: Resolução de diretório pai para arquivos e próprio caminho para diretórios.
4. **`SettingsTests`**:
   - Persistência e leitura de preferências em `UserDefaults`.
