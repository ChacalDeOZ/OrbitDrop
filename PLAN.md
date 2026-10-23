# OrbitDrop — Plano de Engenharia e Fases

Este documento registra o roadmap técnico completo do aplicativo **OrbitDrop**, conversor e manipulador nativo e ilimitado de arquivos para macOS.

---

## Princípios Inegociáveis
1. **Uso Ilimitado:** nenhuma cota, trial de 20 arquivos, contador, paywall ou verificação de licença.
2. **100% Offline:** nenhuma conexão de rede obrigatória ou telemetria invasiva.
3. **Regra Sagrada de Dados:** conversões e edições geram **cópias**. O original nunca é sobrescrito ou apagado (exceto ação explícita de `Move`).
4. **Desacoplamento e Confiabilidade:** nenhuma contagem arbitrária ou rota falsa. Suporte declarado apenas com engine e testes reais.

---

## Roadmap por Fases

### Fase 0 — Estudo de Viabilidade e Protótipo Funcional (STATUS: CONCLUÍDO)
- [x] Estrutura do projeto em Swift Package + bundle `.app`.
- [x] `NSStatusItem` residente na barra de menus.
- [x] Painel flutuante sem ativação (`NSPanel`) e geometria radial (`RadialGeometry`).
- [x] Detecção de modificadores (`Shift`, `Cmd`, `Ctrl`) via `DragIntentDetector`.
- [x] Drop destination nativo com suporte a URLs de arquivos.
- [x] Pipeline real de imagem (`ImagePipeline` via ImageIO: PNG/HEIC/TIFF/BMP → JPEG/PNG).
- [x] `OutputWriter` atômico com prevenção de sobrescrita (`-converted`, `-converted-2`).
- [x] Drop zone flutuante para fallback quando acessibilidade TCC não for concedida.
- [x] Teste de conformidade: 105 conversões contínuas ultrapassando o limite comercial do concorrente.
- [x] Documento de viabilidade empírica (`POC_FINDINGS.md`).

### Fase 1 — Core do Sistema, 3 Rodas e 6 Ações de Arquivo
- [ ] Registro dinâmico de capacidades (`FormatRegistry`).
- [ ] Orquestrador de jobs em lote assíncrono com limites de CPU/RAM.
- [ ] As 6 ações de arquivo: AirDrop (`NSSharingService`), Float Shelf (`NSPanel` persistente), Copy (para clipboard do Finder), Move (com confirmação atômica), Copy Path (UTF-8 e shell-escaped), Terminal (abrir pasta no Terminal ou iTerm2).
- [ ] Configuração de atalhos e preferências básicas (`SettingsView`).

### Fase 2 — Ferramentas de Imagem e Privacidade (CONCLUÍDO)
- [x] T01 Compressão inteligente (otimização de tamanho por busca iterativa).
- [x] T02 Edição e limpeza de metadados (remoção total de GPS/EXIF/IPTC).
- [x] T03–T08: Edit photos, Annotate, Background, Crop, Redact (Vision local), Collage.
- [x] T24 Leitura local de QR code via Vision.
- [x] Conversão múltipla de fotos para PDF (1 página por foto).

### Fase 3 — Motores de Áudio e Vídeo (CONCLUÍDO)
- [x] Integração com AVFoundation e VideoToolbox.
- [x] T09–T15: Trim, Crop, Speed, Join, Save Frames, Split, Redact de vídeo.
- [x] T16–T20: Normalização de volume, Visualizer, Trim, Canais, Bleep de áudio.

### Fase 4 — PDF, Documentos, Planilhas e Compactados (CONCLUÍDO)
- [x] T21–T23: Merge, Organize e Split de PDFs via PDFKit.
- [x] Extração de texto e renderização 300 DPI de PDFs.
- [x] Legendas (SRT ↔ VTT).
- [x] Tratamento seguro de compactados (ZIP via ditto) prevenindo path traversal e zip bombs.

### Fase 5 — Polimento, Acessibilidade e Distribuição (CONCLUÍDO)
- [x] Onboarding nativo em 5 passos com tutorial interativo (`OnboardingWindowController`).
- [x] Total conformidade com VoiceOver e navegação por teclado (`KeyboardNavigator`).
- [x] Hardened runtime, entitlements de segurança e preparação para distribuição (`OrbitDrop.entitlements`).
- [x] Auditoria de conformidade 100% offline e ilimitada (`ComplianceAuditTests`).
