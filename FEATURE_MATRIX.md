# OrbitDrop — Matriz de Recursos e Cobertura Real

> **Regra:** Nunca reportar uma rota ou ferramenta como suportada sem engine real e teste automatizado/manual comprovado.

## 1. Famílias de Formato e Status Atual

| Origem | Destino | Motor | Status | Fixture/Teste |
|---|---|---|---|---|
| `public.png` (PNG) | `public.jpeg` (JPEG) | ImageIO (`CGImageDestination`) | **IMPLEMENTADO & VALIDADO** | `ImagePipelineTests`, `UnlimitedUsageTests`, `FormatRegistryTests` |
| `public.heic` (HEIC) | `public.jpeg` (JPEG) | ImageIO (`CGImageDestination`) | **IMPLEMENTADO & VALIDADO** | `ImagePipeline`, `FormatRegistryTests` |
| `public.tiff` (TIFF) | `public.jpeg` (JPEG) | ImageIO (`CGImageDestination`) | **IMPLEMENTADO & VALIDADO** | `ImagePipeline`, `FormatRegistryTests` |
| `com.microsoft.bmp` (BMP) | `public.jpeg` (JPEG) | ImageIO (`CGImageDestination`) | **IMPLEMENTADO & VALIDADO** | `ImagePipeline`, `FormatRegistryTests` |
| `public.png` (PNG) | `public.png` (PNG) | ImageIO | **IMPLEMENTADO & VALIDADO** | `ImagePipeline`, `FormatRegistryTests` |
| Áudio (WAV, AIFF, M4A) | WAV, M4A, AIFF | AVFoundation / CoreAudio | **IMPLEMENTADO & VALIDADO** | `AudioChannelsTests`, `AudioToolsTests` |
| Vídeo (MP4, MOV) | MP4, MOV, M4A | AVFoundation / VideoToolbox | **IMPLEMENTADO & VALIDADO** | `VideoTranscodeAndFramesTests`, `VideoTimeEditsTests`, `VideoCompositionTests` |
| PDF (Páginas para Imagem 300 DPI) | JPG / PNG | PDFKit / ImageIO | **IMPLEMENTADO & VALIDADO** | `PDFRasterAndTextTests` |
| PDF (Merge / Split / Reorder) | PDF | PDFKit | **IMPLEMENTADO & VALIDADO** | `PDFMergeAndSplitTests`, `PDFPageOrganizerTests` |
| Documentos (HTML, RTF, TXT, JSON, Código) | Markdown (MD) | MarkdownConverter | **IMPLEMENTADO & VALIDADO** | `MarkdownConverterTests` |
| Legendas (SRT ↔ VTT) | SRT, VTT | SubtitleConverter | **IMPLEMENTADO & VALIDADO** | `SubtitleConverterTests` |
| Compactados (ZIP) | ZIP | NSFileCoordinator / ArchiveProcessor | **IMPLEMENTADO & VALIDADO** | `ArchiveProcessorTests` |

## 2. Catálogo de Ferramentas (24 Identificadas + 2 Pesquisa Pendente)

| ID | Nome | Grupo | Status |
|---|---|---|---|
| T01 | Compress | Geral | **IMPLEMENTADO & VALIDADO** (`ImageCompressorTests`) |
| T02 | Edit metadata | Geral | **IMPLEMENTADO & VALIDADO** (`MetadataEditorTests`) |
| T03 | Edit photos | Imagem | **IMPLEMENTADO & VALIDADO** (`ImageEditsTests`) |
| T04 | Annotate photos | Imagem | **IMPLEMENTADO & VALIDADO** (`AnnotationAndCollageTests`) |
| T05 | Add a background | Imagem | **IMPLEMENTADO & VALIDADO** (`ImageEditsTests`) |
| T06 | Crop images | Imagem | **IMPLEMENTADO & VALIDADO** (`ImageEditsTests`) |
| T07 | Redact photos | Imagem | **IMPLEMENTADO & VALIDADO** (`VisionToolsTests`) |
| T08 | Create collage | Imagem | **IMPLEMENTADO & VALIDADO** (`AnnotationAndCollageTests`) |
| T09 | Trim video | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoTimeEditsTests`) |
| T10 | Crop video | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoCompositionTests`) |
| T11 | Change video speed | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoTimeEditsTests`) |
| T12 | Join videos | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoCompositionTests`) |
| T13 | Save video frames | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoTranscodeAndFramesTests`) |
| T14 | Split video | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoCompositionTests`) |
| T15 | Redact video | Vídeo | **IMPLEMENTADO & VALIDADO** (`VideoCompositionTests`) |
| T16 | Normalize volume | Áudio | **IMPLEMENTADO & VALIDADO** (`AudioToolsTests`) |
| T17 | Create audio visualizer | Áudio | **IMPLEMENTADO & VALIDADO** (`AudioVisualizerTests`) |
| T18 | Trim audio | Áudio | **IMPLEMENTADO & VALIDADO** (`AudioToolsTests`) |
| T19 | Convert audio channels | Áudio | **IMPLEMENTADO & VALIDADO** (`AudioChannelsTests`) |
| T20 | Bleep audio | Áudio | **IMPLEMENTADO & VALIDADO** (`AudioToolsTests`) |
| T21 | Merge PDFs | PDF | **IMPLEMENTADO & VALIDADO** (`PDFMergeAndSplitTests`) |
| T22 | Organize PDF pages | PDF | **IMPLEMENTADO & VALIDADO** (`PDFPageOrganizerTests`) |
| T23 | Split PDFs | PDF | **IMPLEMENTADO & VALIDADO** (`PDFMergeAndSplitTests`) |
| T24 | Read QR codes | Utilitário | **IMPLEMENTADO & VALIDADO** (`VisionToolsTests`) |
| T25 | *Não identificada no material público* | - | `pending_research` |
| T26 | *Não identificada no material público* | - | `pending_research` |

## 3. As Seis Ações de Arquivo (Fase 1)

| ID | Ação | Status | Fixture/Teste |
|---|---|---|---|
| A01 | AirDrop | **IMPLEMENTADO & VALIDADO** | `ActionDispatcherTests.testAirDropActionFeasibilityCheck` |
| A02 | Float Shelf | **IMPLEMENTADO & VALIDADO** | `ActionDispatcherTests.testFloatShelfStateManagement` |
| A03 | Copy para Finder | **IMPLEMENTADO & VALIDADO** | `CopyActionsTests.testCopyActionWritesURLsToPasteboard` |
| A04 | Move atômico | **IMPLEMENTADO & VALIDADO** | `TerminalAndMoveTests.testMoveActionTransfersFilesSafely` |
| A05 | Copy Path (UTF-8 / shell) | **IMPLEMENTADO & VALIDADO** | `CopyActionsTests.testCopyPathActionFormatsPathsCorrectly` |
| A06 | Terminal / iTerm2 | **IMPLEMENTADO & VALIDADO** | `TerminalAndMoveTests.testTerminalActionTargetDirectory` |
