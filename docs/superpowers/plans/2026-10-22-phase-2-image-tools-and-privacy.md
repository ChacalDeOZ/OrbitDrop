# Phase 2 Image Tools, Privacy and Vision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o conjunto completo de ferramentas de imagem e privacidade da Fase 2: T01 (Compressão), T02 (Remoção total de metadados), T03–T08 (Ajustes, Anotação, Fundo, Corte, Redação local com Apple Vision, Colagem), T24 (Leitura de QR codes) e consolidação multi-foto para PDF.

**Architecture:** Componentes especializados sob `Sources/OrbitDropKit/Engines/Images/` e `Sources/OrbitDropKit/Vision/`. Manipulação nativa via CoreImage, ImageIO, CoreGraphics e Vision framework da Apple. Todas as ferramentas geram novas cópias atômicas sem sobrescrever o arquivo original.

**Tech Stack:** Swift 6.4, macOS 13+, CoreImage, ImageIO, CoreGraphics, Vision, PDFKit, AppKit, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-22-phase-2-image-tools-and-privacy-design.md`

## Global Constraints
- 100% offline: sem conexões de rede, servidores externos ou bibliotecas de telemetria.
- Zero trial / ilimitado: todas as ferramentas de imagem operam sem bloqueio por cota de arquivos.
- Anonimização irreversível: redação queima pixels opacos sólidos (`RGB 0,0,0`) na matriz raster.
- Não mutabilidade da origem: originais permanecem 100% inalterados com nomes preservados.

## Review Focus
- Imagem comprimida para alvo irreal (ex: 1 KB) -> atinge limite seguro sem loop infinito.
- Remoção de metadados de imagem que já não tem EXIF/GPS -> gera cópia válida sem exceção.
- Redação em foto sem rostos detectados -> produz cópia intacta com sufixo determinístico.
- Criação de PDF a partir de mix heterogêneo de formatos (PNG + HEIC + TIFF) -> PDF com contagem exata de páginas.
- Imagem sem QR code submetida ao QRCodeReader -> retorna lista vazia sem travar.

---

### Task 1: T01 `ImageCompressor` (Compressão Inteligente e Busca Iterativa)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Images/ImageCompressor.swift`
- Test: `Tests/OrbitDropKitTests/ImageCompressorTests.swift`

**Interfaces:**
- Consumes: `OutputWriter`, `CGImageSource`, `CGImageDestination`
- Produces: `ImageCompressor.compress(sourceURL:targetBytes:maxQualitySteps:) throws -> URL`

- [ ] **Step 1: Escrever teste de compressão de imagem**
Criar `Tests/OrbitDropKitTests/ImageCompressorTests.swift` testando:
1. Redução de tamanho de foto sintética de teste para um teto de bytes especificado.
2. Saída gerada válida e decodificável pelo ImageIO.
3. Tratamento seguro de alvo muito baixo sem loop infinito.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter ImageCompressorTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ImageCompressor`**
Busca iterativa de fator de qualidade (de 0.90 até 0.15) com fallback para downsampling se necessário.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter ImageCompressorTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Images/ImageCompressor.swift Tests/OrbitDropKitTests/ImageCompressorTests.swift
git commit -m "feat(engine): implement intelligent ImageCompressor"
```

---

### Task 2: T02 `MetadataEditor` (Inspeção e Remoção Total de Metadados)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Images/MetadataEditor.swift`
- Test: `Tests/OrbitDropKitTests/MetadataEditorTests.swift`

**Interfaces:**
- Consumes: `OutputWriter`, `CGImageSource`, `CGImageDestination`
- Produces: `MetadataEditor.stripAllMetadata(sourceURL:) throws -> URL`, `MetadataEditor.readMetadata(sourceURL:) -> [String: Any]`

- [ ] **Step 1: Escrever teste de metadados**
Criar `Tests/OrbitDropKitTests/MetadataEditorTests.swift` testando:
1. Leitura de metadados de fixture sintético com tags GPS/EXIF injetadas.
2. Remoção via `stripAllMetadata` e validação de que a cópia de saída não contém `kCGImagePropertyGPSDictionary` nem `kCGImagePropertyExifDictionary`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter MetadataEditorTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `MetadataEditor`**
Expurgo atômico de metadados regravando imagem com dicionário de propriedades vazio.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter MetadataEditorTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Images/MetadataEditor.swift Tests/OrbitDropKitTests/MetadataEditorTests.swift
git commit -m "feat(engine): implement MetadataEditor with complete EXIF/GPS stripping"
```

---

### Task 3: T03 `ImageAdjustments`, T05 `ImageBackgroundAdder` e T06 `ImageCropper`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Images/ImageAdjustments.swift`
- Create: `Sources/OrbitDropKit/Engines/Images/ImageBackgroundAdder.swift`
- Create: `Sources/OrbitDropKit/Engines/Images/ImageCropper.swift`
- Test: `Tests/OrbitDropKitTests/ImageEditsTests.swift`

**Interfaces:**
- Consumes: `CoreImage`, `OutputWriter`
- Produces: `ImageAdjustments.apply(...)`, `ImageBackgroundAdder.addBackground(...)`, `ImageCropper.crop(...)`

- [ ] **Step 1: Escrever teste de filtros, fundo e corte**
Criar `Tests/OrbitDropKitTests/ImageEditsTests.swift` testando:
1. `ImageAdjustments`: aplicação de contraste/brilho via CoreImage gerando imagem modificada válida.
2. `ImageCropper`: corte de imagem 100x100 para proporção 1:1 de 50x50.
3. `ImageBackgroundAdder`: adição de margem/fundo colorido aumentando dimensões da imagem final.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter ImageEditsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ImageAdjustments`, `ImageBackgroundAdder` e `ImageCropper`**
Implementar manipulação com `CIContext`, `CIFilter` e `CGContext`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter ImageEditsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Images/ImageAdjustments.swift Sources/OrbitDropKit/Engines/Images/ImageBackgroundAdder.swift Sources/OrbitDropKit/Engines/Images/ImageCropper.swift Tests/OrbitDropKitTests/ImageEditsTests.swift
git commit -m "feat(engine): implement ImageAdjustments, BackgroundAdder and Cropper"
```

---

### Task 4: T04 `ImageAnnotator` e T08 `ImageCollageBuilder`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Images/ImageAnnotator.swift`
- Create: `Sources/OrbitDropKit/Engines/Images/ImageCollageBuilder.swift`
- Test: `Tests/OrbitDropKitTests/AnnotationAndCollageTests.swift`

**Interfaces:**
- Consumes: `CoreGraphics`, `OutputWriter`
- Produces: `ImageAnnotator.annotate(...)`, `ImageCollageBuilder.createCollage(from:layout:)`

- [ ] **Step 1: Escrever teste de anotação e colagem**
Criar `Tests/OrbitDropKitTests/AnnotationAndCollageTests.swift` testando:
1. `ImageAnnotator`: renderização de retângulo e texto sobre bitmap.
2. `ImageCollageBuilder`: junção de 2 imagens 50x50 em grid 2x1 resultando em imagem de 100x50.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter AnnotationAndCollageTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ImageAnnotator` e `ImageCollageBuilder`**
Renderização matricial com `CGContext`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter AnnotationAndCollageTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Images/ImageAnnotator.swift Sources/OrbitDropKit/Engines/Images/ImageCollageBuilder.swift Tests/OrbitDropKitTests/AnnotationAndCollageTests.swift
git commit -m "feat(engine): implement ImageAnnotator and ImageCollageBuilder"
```

---

### Task 5: T07 `ImageRedactor` e T24 `QRCodeReader` (Apple Vision)

**Files:**
- Create: `Sources/OrbitDropKit/Vision/ImageRedactor.swift`
- Create: `Sources/OrbitDropKit/Vision/QRCodeReader.swift`
- Test: `Tests/OrbitDropKitTests/VisionToolsTests.swift`

**Interfaces:**
- Consumes: `Vision`, `ImageIO`, `OutputWriter`
- Produces: `ImageRedactor.redact(sourceURL:regions:) throws -> URL`, `QRCodeReader.read(from:) async throws -> [String]`

- [ ] **Step 1: Escrever teste de redação e QR Code**
Criar `Tests/OrbitDropKitTests/VisionToolsTests.swift` testando:
1. `ImageRedactor`: queima de tarja retangular opaca e verificação de que pixels na região têm cor `RGB 0,0,0`.
2. `QRCodeReader`: geração de código QR sintético via CoreImage e decodificação correta via Vision local.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter VisionToolsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ImageRedactor` e `QRCodeReader`**
Uso nativo de `VNDetectFaceRectanglesRequest`, `VNRecognizeTextRequest` e `VNDetectBarcodesRequest`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter VisionToolsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Vision/ Tests/OrbitDropKitTests/VisionToolsTests.swift
git commit -m "feat(vision): implement local ImageRedactor and QRCodeReader"
```

---

### Task 6: Multi-imagem para PDF (`ImageToPDFConverter`)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Images/ImageToPDFConverter.swift`
- Test: `Tests/OrbitDropKitTests/ImageToPDFTests.swift`

**Interfaces:**
- Consumes: `PDFKit`, `OutputWriter`, `CGImageSource`
- Produces: `ImageToPDFConverter.createPDF(from:outputDirectory:) throws -> URL`

- [ ] **Step 1: Escrever teste de conversão multi-imagem para PDF**
Criar `Tests/OrbitDropKitTests/ImageToPDFTests.swift` testando:
1. Agrupamento de 3 fotos sintéticas (PNG, JPG) em um único arquivo PDF.
2. Leitura com `PDFDocument` conferindo `pageCount == 3` e dimensões correspondentes.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter ImageToPDFTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `ImageToPDFConverter`**
Geração de PDF via `CGContext(consumer: ...)` adicionando cada foto em uma página com proporção natural.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter ImageToPDFTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Images/ImageToPDFConverter.swift Tests/OrbitDropKitTests/ImageToPDFTests.swift
git commit -m "feat(pdf): implement multi-image to PDF converter"
```

---

### Task 7: Integração no Menu Radial de Tools, Status Bar e Recompilação do Bundle

**Files:**
- Modify: `Sources/OrbitDropApp/AppDelegate.swift`
- Modify: `FEATURE_MATRIX.md`
- Modify: `TASKS.md`

- [ ] **Step 1: Conectar ferramentas na roda de Tools (`Command`) do `AppDelegate`**
Mapear: `tool.compress`, `tool.metadata`, `tool.adjust`, `tool.crop`, `tool.background`, `tool.redact`, `tool.collage`, `tool.qr`, `tool.pdf`.

- [ ] **Step 2: Executar suite completa de testes**
Run: `swift test`
Expected: PASS com 100% dos testes.

- [ ] **Step 3: Recompilar e empacotar bundle release**
Run: `./Scripts/build_app.sh`
Expected: Bundle `build/OrbitDrop.app` gerado e assinado com sucesso.

- [ ] **Step 4: Atualizar `FEATURE_MATRIX.md` e `TASKS.md`**
Registrar ferramentas da Fase 2 como concluídas.

- [ ] **Step 5: Commit final da Fase 2**
```bash
git add Sources/OrbitDropApp/ FEATURE_MATRIX.md TASKS.md
git commit -m "feat(phase-2): integrate image tools, privacy and vision into OrbitDropApp"
```
