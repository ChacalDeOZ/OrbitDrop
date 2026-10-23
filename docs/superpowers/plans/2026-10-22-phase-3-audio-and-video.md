# Phase 3 Audio and Video Engines Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar o conjunto completo de ferramentas de áudio e vídeo da Fase 3: T09–T15 (Corte, Crop, Velocidade, Concatenação, Extração de frames, Divisão e Redação de vídeo) e T16–T20 (Normalização de volume, Visualizer, Trim, Canais e Bleep de áudio), além de transcodificação nativa de contêineres e extração de áudio via AVFoundation e CoreAudio.

**Architecture:** Componentes desacoplados em `Sources/OrbitDropKit/Engines/Audio/` e `Sources/OrbitDropKit/Engines/Video/`. Processamento acelerado por hardware da Apple (VideoToolbox e CoreAudio), sem dependências externas não-livres, gerando sempre cópias atômicas sem sobrescrever o arquivo original.

**Tech Stack:** Swift 6.4, macOS 13+, AVFoundation, CoreAudio, VideoToolbox, CoreGraphics, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-22-phase-3-audio-video-design.md`

## Global Constraints
- 100% offline: sem dependências de rede, serviços externos ou telemetria.
- Zero trial / uso ilimitado: todas as ferramentas de áudio e vídeo operam sem bloqueio por cota.
- Arquivos de origem intactos: todas as operações geram novas cópias com nomes resolvidos atomicamente.
- Concorrência Swift 6 completa com cancelamento cooperativo de exportSessions.

## Review Focus
- Vídeo sem trilha de áudio -> operações de corte, velocidade e join continuam funcionando normalmente.
- Vídeo com VFR ou rotação de metadata -> mantém orientação correta via `preferredTransform`.
- Síntese de bleep senoidal 1000 Hz -> envelope suave de fade para evitar cliques acústicos.
- Concatenação de vídeos heterogêneos -> normalização de dimensões e framerate sem aborto.
- Normalização de áudio em arquivo de silêncio absoluto -> preserva o silêncio sem divisão por zero.

---

### Task 1: Gerador de Fixtures Sintéticos e T19 `AudioChannelConverter`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Audio/SyntheticMediaGenerator.swift`
- Create: `Sources/OrbitDropKit/Engines/Audio/AudioChannelConverter.swift`
- Test: `Tests/OrbitDropKitTests/AudioChannelsTests.swift`

**Interfaces:**
- Consumes: `AVAudioFile`, `AVAudioPCMBuffer`
- Produces: `SyntheticMediaGenerator.createWAV(...)`, `AudioChannelConverter.convertChannels(...)`

- [ ] **Step 1: Escrever teste de conversão de canais de áudio**
Criar `Tests/OrbitDropKitTests/AudioChannelsTests.swift` testando:
1. Geração de fixture WAV estéreo sintético (44.1 kHz, 16-bit, 1s).
2. Conversão de estéreo para mono -> assert de que o arquivo gerado tem `channelCount == 1`.
3. Conversão de mono para estéreo -> assert de que o arquivo gerado tem `channelCount == 2`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter AudioChannelsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `SyntheticMediaGenerator` e `AudioChannelConverter`**
Implementar geração sintética de ondas PCM e conversão estéreo/mono.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter AudioChannelsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Audio/ Tests/OrbitDropKitTests/AudioChannelsTests.swift
git commit -m "feat(audio): implement SyntheticMediaGenerator and AudioChannelConverter"
```

---

### Task 2: T16 `AudioNormalizer`, T18 `AudioTrimmer` e T20 `AudioBleeper`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Audio/AudioNormalizer.swift`
- Create: `Sources/OrbitDropKit/Engines/Audio/AudioTrimmer.swift`
- Create: `Sources/OrbitDropKit/Engines/Audio/AudioBleeper.swift`
- Test: `Tests/OrbitDropKitTests/AudioToolsTests.swift`

**Interfaces:**
- Consumes: `AVAudioFile`, `AVAudioPCMBuffer`, `OutputWriter`
- Produces: `AudioNormalizer.normalize(...)`, `AudioTrimmer.trim(...)`, `AudioBleeper.bleep(...)`

- [ ] **Step 1: Escrever teste de ferramentas de áudio**
Criar `Tests/OrbitDropKitTests/AudioToolsTests.swift` testando:
1. `AudioNormalizer`: varredura de picos e ajuste de ganho mantendo o teto abaixo de -1 dBFS.
2. `AudioTrimmer`: corte de trecho de 1s para 0.5s e verificação de contagem de frames.
3. `AudioBleeper`: injeção de tom de 1000 Hz em janela de tempo com fade suave.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter AudioToolsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `AudioNormalizer`, `AudioTrimmer` e `AudioBleeper`**
Implementar processamento de buffers PCM e cálculo de amplitude.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter AudioToolsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Audio/AudioNormalizer.swift Sources/OrbitDropKit/Engines/Audio/AudioTrimmer.swift Sources/OrbitDropKit/Engines/Audio/AudioBleeper.swift Tests/OrbitDropKitTests/AudioToolsTests.swift
git commit -m "feat(audio): implement AudioNormalizer, Trimmer and Bleeper"
```

---

### Task 3: T17 `AudioVisualizer` (Geração de Vídeo a partir de Áudio)

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Audio/AudioVisualizer.swift`
- Test: `Tests/OrbitDropKitTests/AudioVisualizerTests.swift`

**Interfaces:**
- Consumes: `AVAssetWriter`, `AVAudioFile`, `OutputWriter`
- Produces: `AudioVisualizer.createVisualizerVideo(audioURL:outputDirectory:) async throws -> URL`

- [ ] **Step 1: Escrever teste de visualizer de áudio**
Criar `Tests/OrbitDropKitTests/AudioVisualizerTests.swift` testando:
1. Geração de vídeo MP4 a partir de arquivo de áudio sintético.
2. Validação de que a saída gerada é um vídeo válido decodificável pelo `AVURLAsset`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter AudioVisualizerTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `AudioVisualizer`**
Renderização de quadros de forma de onda com `AVAssetWriterInputPixelBufferAdaptor`.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter AudioVisualizerTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Audio/AudioVisualizer.swift Tests/OrbitDropKitTests/AudioVisualizerTests.swift
git commit -m "feat(audio): implement AudioVisualizer generating video from audio waveform"
```

---

### Task 4: `VideoTranscoder` e T13 `VideoFrameExtractor`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Video/VideoTranscoder.swift`
- Create: `Sources/OrbitDropKit/Engines/Video/VideoFrameExtractor.swift`
- Test: `Tests/OrbitDropKitTests/VideoTranscodeAndFramesTests.swift`

**Interfaces:**
- Consumes: `AVAssetExportSession`, `AVAssetImageGenerator`, `OutputWriter`
- Produces: `VideoTranscoder.transcode(...)`, `VideoFrameExtractor.extractFrames(...)`

- [ ] **Step 1: Escrever teste de transcodificação e extração de frames**
Criar `Tests/OrbitDropKitTests/VideoTranscodeAndFramesTests.swift` testando:
1. Criação de clipe de vídeo sintético de 1s via `SyntheticMediaGenerator`.
2. Extração de áudio de vídeo para M4A.
3. Extração de frame em t=0.5s gerando PNG válido.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter VideoTranscodeAndFramesTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `VideoTranscoder` e `VideoFrameExtractor`**
Implementar sessões de exportação nativas e gerador de imagens assíncrono.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter VideoTranscodeAndFramesTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Video/VideoTranscoder.swift Sources/OrbitDropKit/Engines/Video/VideoFrameExtractor.swift Tests/OrbitDropKitTests/VideoTranscodeAndFramesTests.swift
git commit -m "feat(video): implement VideoTranscoder and VideoFrameExtractor"
```

---

### Task 5: T09 `VideoTrimmer` e T11 `VideoSpeedController`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Video/VideoTrimmer.swift`
- Create: `Sources/OrbitDropKit/Engines/Video/VideoSpeedController.swift`
- Test: `Tests/OrbitDropKitTests/VideoTimeEditsTests.swift`

**Interfaces:**
- Consumes: `AVMutableComposition`, `AVAssetExportSession`, `OutputWriter`
- Produces: `VideoTrimmer.trim(...)`, `VideoSpeedController.changeSpeed(...)`

- [ ] **Step 1: Escrever teste de corte e velocidade de vídeo**
Criar `Tests/OrbitDropKitTests/VideoTimeEditsTests.swift` testando:
1. `VideoTrimmer`: corte de clipe de 1s para 0.5s e validação de duração.
2. `VideoSpeedController`: alteração de velocidade 2.0x e validação de duração reduzida pela metade.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter VideoTimeEditsTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `VideoTrimmer` e `VideoSpeedController`**
Composição de faixas de vídeo e áudio com `scaleTimeRange` e preservação espectral de pitch.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter VideoTimeEditsTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Video/VideoTrimmer.swift Sources/OrbitDropKit/Engines/Video/VideoSpeedController.swift Tests/OrbitDropKitTests/VideoTimeEditsTests.swift
git commit -m "feat(video): implement VideoTrimmer and VideoSpeedController"
```

---

### Task 6: T10 `VideoCropper`, T12 `VideoJoiner`, T14 `VideoSplitter` e T15 `VideoRedactor`

**Files:**
- Create: `Sources/OrbitDropKit/Engines/Video/VideoCropper.swift`
- Create: `Sources/OrbitDropKit/Engines/Video/VideoJoiner.swift`
- Create: `Sources/OrbitDropKit/Engines/Video/VideoSplitter.swift`
- Create: `Sources/OrbitDropKit/Engines/Video/VideoRedactor.swift`
- Test: `Tests/OrbitDropKitTests/VideoCompositionTests.swift`

**Interfaces:**
- Consumes: `AVMutableVideoComposition`, `OutputWriter`
- Produces: `VideoCropper.crop(...)`, `VideoJoiner.join(...)`, `VideoSplitter.split(...)`, `VideoRedactor.redact(...)`

- [ ] **Step 1: Escrever teste de composição de vídeo**
Criar `Tests/OrbitDropKitTests/VideoCompositionTests.swift` testando:
1. `VideoJoiner`: junção de 2 clipes sintéticos de 0.5s gerando saída de 1.0s.
2. `VideoSplitter`: divisão de clipe de 1s em 2 partes de 0.5s.
3. `VideoRedactor`: adição de máscara retangular em vídeo.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter VideoCompositionTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `VideoCropper`, `VideoJoiner`, `VideoSplitter` e `VideoRedactor`**
Composições de vídeo com `AVMutableVideoCompositionInstruction` e camadas de animação.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter VideoCompositionTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Engines/Video/ Tests/OrbitDropKitTests/VideoCompositionTests.swift
git commit -m "feat(video): implement VideoCropper, Joiner, Splitter and Redactor"
```

---

### Task 7: Atualização do `FormatRegistry`, `AppDelegate`, Recompilação e Validação

**Files:**
- Modify: `Sources/OrbitDropKit/FormatRegistry/FormatRegistry.swift`
- Modify: `Sources/OrbitDropApp/AppDelegate.swift`
- Modify: `FEATURE_MATRIX.md`
- Modify: `TASKS.md`

- [ ] **Step 1: Expandir `FormatRegistry` com arestas de vídeo e áudio**
Adicionar suporte: MP4, MOV, M4A, WAV, AIFF.

- [ ] **Step 2: Conectar ferramentas de áudio e vídeo no `AppDelegate`**
Roteamento para T09–T20 no método `processMediaTool`.

- [ ] **Step 3: Executar suite completa de testes**
Run: `swift test`
Expected: PASS com 100% dos testes.

- [ ] **Step 4: Recompilar e empacotar bundle release**
Run: `./Scripts/build_app.sh`
Expected: Bundle `build/OrbitDrop.app` gerado e assinado com sucesso.

- [ ] **Step 5: Atualizar `FEATURE_MATRIX.md` e `TASKS.md`**
Registrar a conclusão integral das ferramentas de áudio e vídeo da Fase 3.

- [ ] **Step 6: Commit final da Fase 3**
```bash
git add Sources/OrbitDropKit/FormatRegistry/ Sources/OrbitDropApp/ FEATURE_MATRIX.md TASKS.md
git commit -m "feat(phase-3): integrate audio and video engines into OrbitDropApp"
```
