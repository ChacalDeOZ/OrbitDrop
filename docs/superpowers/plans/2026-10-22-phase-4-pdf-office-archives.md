# Phase 4 PDF, Subtitles and Archives Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar as ferramentas finais de PDF (T21 Merge, T22 Organize, T23 Split, Render 300 DPI, Extração de texto), conversão de legendas (SRT ↔ VTT) e processamento seguro de compactados (ZIP, TAR, GZ) com prevenção contra path traversal e zip bombs.

**Architecture:** Módulos em `Sources/OrbitDropKit/Engines/PDF/`, `Sources/OrbitDropKit/Engines/Subtitles/` e `Sources/OrbitDropKit/Engines/Archives/`. Processamento nativo via PDFKit, CoreGraphics e APIs seguras de arquivo, gerando sempre cópias atômicas sem sobrescrita.

**Tech Stack:** Swift 6.4, macOS 13+, PDFKit, CoreGraphics, ImageIO, Foundation, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-22-phase-4-pdf-office-archives-design.md`

## Global Constraints
- 100% offline: sem servidores externos, rede ou telemetria.
- Zero trial / uso ilimitado: nenhuma cota ou bloqueio em processamentos de PDF ou compactação.
- Arquivos de origem 100% preservados em novas cópias atômicas.
- Segurança estrita em arquivos compactados: bloqueio mandatário de `../` e cotas de descompressão.

## Review Focus
- PDF protegido por senha -> rejeitado com erro amigável sem travar.
- Rasterização 300 DPI em páginas grandes -> memória liberada por página após exportação.
- SubtitleParser com timestamps quebrados -> erro claro sem loop infinito.
- Archive com path traversal malicioso (`../malicious.sh`) -> abortado com rejeição de segurança.
- Merge de PDFs com tamanhos de página heterogêneos -> preserva dimensões nativas de cada página.

---

### Task 1: T21 `PDFMerger` e T23 `PDFSplitter`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/PDF/PDFMerger.swift`
- Create: `Sources/OrbitDropKit/Engines/PDF/PDFSplitter.swift`
- Test: `Tests/OrbitDropKitTests/PDFMergeAndSplitTests.swift`

**Interfaces:**
- Consumes: `PDFDocument`, `PDFPage`, `OutputWriter`
- Produces: `PDFMerger.merge(sources:directory:) throws -> URL`, `PDFSplitter.split(sourceURL:directory:) throws -> [URL]`

- [ ] **Step 1: Escrever teste de Merge e Split de PDF**
Criar `Tests/OrbitDropKitTests/PDFMergeAndSplitTests.swift` testando:
1. Geração programática de 2 PDFs sintéticos de 1 página.
2. `PDFMerger`: merge de ambos gerando 1 arquivo de 2 páginas.
3. `PDFSplitter`: split do arquivo gerando 2 arquivos de 1 página.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter PDFMergeAndSplitTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `PDFMerger` e `PDFSplitter`**
Manipulação segura via `PDFKit`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter PDFMergeAndSplitTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/PDF/ Tests/OrbitDropKitTests/PDFMergeAndSplitTests.swift
git commit -m "feat(pdf): implement PDFMerger and PDFSplitter"
```

---

### Task 2: T22 `PDFPageOrganizer` (Reordenação, Rotação e Exclusão)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/PDF/PDFPageOrganizer.swift`
- Test: `Tests/OrbitDropKitTests/PDFPageOrganizerTests.swift`

**Interfaces:**
- Consumes: `PDFDocument`, `OutputWriter`
- Produces: `PDFPageOrganizer.reorganize(...) throws -> URL`

- [ ] **Step 1: Escrever teste de organização de páginas de PDF**
Criar `Tests/OrbitDropKitTests/PDFPageOrganizerTests.swift` testando:
1. Rotação de página 0 em 90 graus -> assert `page.rotation == 90`.
2. Exclusão de página -> assert `pageCount` reduzido.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter PDFPageOrganizerTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `PDFPageOrganizer`**
Aplicação de transformações nas páginas do `PDFDocument`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter PDFPageOrganizerTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/PDF/PDFPageOrganizer.swift Tests/OrbitDropKitTests/PDFPageOrganizerTests.swift
git commit -m "feat(pdf): implement PDFPageOrganizer for rotation and reordering"
```

---

### Task 3: `PDFRasterizer` (300 DPI) e `PDFTextExtractor`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/PDF/PDFRasterizer.swift`
- Create: `Sources/OrbitDropKit/Engines/PDF/PDFTextExtractor.swift`
- Test: `Tests/OrbitDropKitTests/PDFRasterAndTextTests.swift`

**Interfaces:**
- Consumes: `PDFDocument`, `CGContext`, `OutputWriter`
- Produces: `PDFRasterizer.renderPages(...) throws -> [URL]`, `PDFTextExtractor.extractText(...) throws -> URL`

- [ ] **Step 1: Escrever teste de rasterização 300 DPI e extração de texto**
Criar `Tests/OrbitDropKitTests/PDFRasterAndTextTests.swift` testando:
1. `PDFRasterizer`: página de 612x792 pt (Letter) renderizada a 300 DPI gerando imagem de 2550x3300 pixels.
2. `PDFTextExtractor`: extração de texto preservando strings inseridas no documento.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter PDFRasterAndTextTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `PDFRasterizer` e `PDFTextExtractor`**
Renderização em bitmap de alta resolução via escala 300/72 e extração de strings.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter PDFRasterAndTextTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/PDF/PDFRasterizer.swift Sources/OrbitDropKit/Engines/PDF/PDFTextExtractor.swift Tests/OrbitDropKitTests/PDFRasterAndTextTests.swift
git commit -m "feat(pdf): implement PDFRasterizer (300 DPI) and PDFTextExtractor"
```

---

### Task 4: Conversor de Legendas (`SubtitleConverter`)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Subtitles/SubtitleConverter.swift`
- Test: `Tests/OrbitDropKitTests/SubtitleConverterTests.swift`

**Interfaces:**
- Consumes: `OutputWriter`
- Produces: `SubtitleConverter.convert(sourceURL:targetFormat:) throws -> URL`

- [ ] **Step 1: Escrever teste de conversão de legendas**
Criar `Tests/OrbitDropKitTests/SubtitleConverterTests.swift` testando:
1. SRT para VTT: adição de cabeçalho `WEBVTT` e substituição de vírgula por ponto nos timestamps.
2. VTT para SRT: remoção do cabeçalho e substituição de pontos por vírgulas nos timestamps.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter SubtitleConverterTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `SubtitleConverter`**
Parser e transformador de timestamps e quebras de linha com encoding UTF-8.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter SubtitleConverterTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Subtitles/ Tests/OrbitDropKitTests/SubtitleConverterTests.swift
git commit -m "feat(subtitles): implement SubtitleConverter for SRT and VTT"
```

---

### Task 5: Compactador Seguro com Proteção de Path Traversal (`ArchiveProcessor`)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Archives/ArchiveProcessor.swift`
- Test: `Tests/OrbitDropKitTests/ArchiveProcessorTests.swift`

**Interfaces:**
- Consumes: `NSFileCoordinator`, `FileManager`, `OutputWriter`
- Produces: `ArchiveProcessor.createZIP(...) throws -> URL`, `ArchiveProcessor.extract(...) throws -> URL`

- [ ] **Step 1: Escrever teste de compactação e segurança contra traversal**
Criar `Tests/OrbitDropKitTests/ArchiveProcessorTests.swift` testando:
1. Criação de arquivo ZIP a partir de pasta com arquivos.
2. Descompactação e conferência de integridade.
3. Bloqueio estrito de arquivos contendo `../` no caminho.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter ArchiveProcessorTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ArchiveProcessor`**
Criação de ZIP via `NSFileCoordinator` e descompactação segura com validação de caminho canônico.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter ArchiveProcessorTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Archives/ Tests/OrbitDropKitTests/ArchiveProcessorTests.swift
git commit -m "feat(archives): implement secure ArchiveProcessor with path traversal guards"
```

---

### Task 6: Atualização do `FormatRegistry`, `AppDelegate`, Recompilação e Validação

**Files:**
- Modify: `Sources/OrbitDropKit/FormatRegistry/FormatRegistry.swift`
- Modify: `Sources/OrbitDropApp/AppDelegate.swift`
- Modify: `FEATURE_MATRIX.md`
- Modify: `TASKS.md`

- [ ] **Step 1: Integrar PDF, legendas e arquivos compactados no `FormatRegistry` e `AppDelegate`**
1. Atualizar `FormatRegistry` com arestas de PDF (saídas PNG, JPG a 300 DPI, TXT, MD), legendas (SRT ↔ VTT) e compactados (ZIP, TAR).
2. Adicionar ferramentas T21, T22, T23 no menu `Tools` do `AppDelegate`.
3. Roteamento de execução das novas ferramentas.

- [ ] **Step 2: Executar suite completa de testes**
Run: `swift test`
Expected: PASS com 100% dos testes.

- [ ] **Step 3: Recompilar e empacotar bundle release**
Run: `./Scripts/build_app.sh`
Expected: Bundle `build/OrbitDrop.app` gerado e assinado com sucesso.

- [ ] **Step 4: Atualizar `FEATURE_MATRIX.md` e `TASKS.md`**
Registrar conclusão integral da Fase 4 e totalidade das 24 ferramentas públicas.

- [ ] **Step 5: Commit final da Fase 4**
```bash
git add Sources/OrbitDropKit/FormatRegistry/ Sources/OrbitDropApp/ FEATURE_MATRIX.md TASKS.md
git commit -m "feat(phase-4): integrate PDF tools, subtitles and archives into OrbitDropApp"
```
