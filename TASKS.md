# OrbitDrop — Tarefas e Checklist Executável

## Fase 0 — Viabilidade e Protótipo (CONCLUÍDA)
- [x] T0.1 Inicializar repositório Git e definir `Package.swift` compatível com macOS 13+.
- [x] T0.2 Implementar modelos fundamentais (`FileDescriptor`, `DragPayload`, `WheelMode`, `RadialItem`) e testes unitários.
- [x] T0.3 Implementar motor trigonométrico `RadialGeometry` (ângulos, setores, raios, clamping de borda) e testes.
- [x] T0.4 Implementar `OutputWriter` (escrita atômica, staging temporário, sufixos `-converted`, `-converted-N`) e testes.
- [x] T0.5 Implementar `ImagePipeline` nativo via ImageIO (PNG/HEIC/TIFF → JPEG) e testes com fixtures sintéticos.
- [x] T0.6 Implementar teste de estresse de cota (105 conversões contínuas validando execução livre após 20 e 100 arquivos).
- [x] T0.7 Implementar verificador de permissão `AccessibilityChecker` e detector de intenção global `DragIntentDetector`.
- [x] T0.8 Implementar UI nativa AppKit: `RadialWheelView`, `RadialPanelController`, `DropZoneWindowController`, `StatusItemController`.
- [x] T0.9 Implementar ponto de entrada `AppDelegate`, `main.swift`, constantes `AppBranding` e script `Scripts/build_app.sh`.
- [x] T0.10 Montar bundle `OrbitDrop.app` assinado ad-hoc e validar execução.
- [x] T0.11 Criar documentação estrutural: `PLAN.md`, `TASKS.md`, `DECISIONS.md`, `FEATURE_MATRIX.md`, `THIRD_PARTY_NOTICES.md`, `POC_FINDINGS.md`, `README.md`.

## Fase 1 — Core do Sistema e Ações (CONCLUÍDA)
- [x] T1.1 Criar `FormatRegistry` declarativo com validação de grafos de conversão e interseção multi-arquivo.
- [x] T1.2 Implementar fila de jobs assíncrona (`JobQueueActor`) com limite de concorrência e cancelamento cooperativo.
- [x] T1.3 Implementar Ação A01: AirDrop via `NSSharingService` (`AirDropAction`).
- [x] T1.4 Implementar Ação A02: Float Shelf flutuante para reter arquivos temporariamente com drag-out (`FloatShelfController`).
- [x] T1.5 Implementar Ação A03: Copy (colocando objetos no `NSPasteboard` prontos para colar no Finder via `CopyAction`).
- [x] T1.6 Implementar Ação A04: Move (com resolução atômica de colisões e movimentação segura via `MoveAction`).
- [x] T1.7 Implementar Ação A05: Copy Path (UTF-8 legível separado por quebra de linha via `CopyPathAction`).
- [x] T1.8 Implementar Ação A06: Terminal (abertura do diretório pai ou pasta no Terminal/iTerm2 via `TerminalAction`).
- [x] T1.9 Implementar tela de configurações `SettingsWindowController` e persistência via `SettingsManager`.
- [x] T1.10 Integrar motor `FormatRegistry`, `JobQueueActor` e `ActionDispatcher` no `AppDelegate`.

## Fase 2 — Ferramentas de Imagem e Privacidade (CONCLUÍDA)
- [x] T2.1 Implementar ferramenta T01 Compressão inteligente de imagens e busca iterativa de qualidade.
- [x] T2.2 Implementar ferramenta T02 Edição e remoção total de metadados (EXIF/GPS/IPTC).
- [x] T2.3 Implementar ferramentas T03–T08 (Edição, Anotações, Fundo, Corte, Redação local via Vision, Colagem).
- [x] T2.4 Implementar ferramenta T24 Leitura local de QR Codes via Apple Vision framework.
- [x] T2.5 Implementar criação de PDF consolidado a partir de imagens múltiplas selecionadas.

## Fase 3 — Áudio e Vídeo (CONCLUÍDA)
- [x] T3.1 Validar matriz de contêiner/codec com AVFoundation, VideoToolbox e CoreAudio nativos.
- [x] T3.2 Implementar T09–T15 (Trim, Crop, Speed com pitch espectral, Join, Frames em PNG, Split em N partes, Redact de vídeo com tarjas opacas).
- [x] T3.3 Implementar T16–T20 (Normalização com prevenção de clipping, Visualizer MP4, Trim, Conversão de canais mono/stereo, Bleep senoidal 1000 Hz).
- [x] T3.4 Criar fixtures sintéticos de áudio e vídeo e testes automatizados completos.

## Fase 4 — PDF, Office, Planilhas, Legendas e Compactados (CONCLUÍDA)
- [x] T4.1 Implementar T21 (Merge PDFs), T22 (Organize PDF pages) e T23 (Split PDFs) via PDFKit.
- [x] T4.2 Implementar renderização de páginas PDF para imagens em 300 DPI nativos (`PDFRasterizer`).
- [x] T4.3 Implementar extração de texto PDF para TXT e Markdown estruturado (`PDFTextExtractor`).
- [x] T4.4 Implementar conversor de legendas SRT ↔ VTT com preservação de timestamps e Unicode (`SubtitleConverter`).
- [x] T4.5 Implementar tratamento seguro de compactados (ZIP) com proteção contra path traversal e zip bombs (`ArchiveProcessor`).

## Fase 5 — Polimento, Acessibilidade e Distribuição (CONCLUÍDA)
- [x] T5.1 Construir tela de Onboarding nativa em 5 passos com tutorial interativo de drag + tecla (`OnboardingWindowController`).
- [x] T5.2 Revisão de acessibilidade completa (VoiceOver labels e navegação por teclado via `KeyboardNavigator`).
- [x] T5.3 Configuração de entitlements de segurança offline (`OrbitDrop.entitlements`) e documentação de release (`DISTRIBUTION.md`, `PRIVACY.md`).
- [x] T5.4 Auditoria automatizada de conformidade (zero StoreKit, zero paywall, 24 ferramentas mapeadas via `ComplianceAuditTests`).
