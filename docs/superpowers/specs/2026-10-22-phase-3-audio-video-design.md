# Especificação Técnica — OrbitDrop: Fase 3 (Motores de Áudio e Vídeo)

**Data:** 2026-10-22  
**Status:** Aprovado para Planejamento  
**Objetivo:** Implementar os motores de processamento e conversão de áudio e vídeo via AVFoundation, VideoToolbox e CoreAudio: T09–T15 (Corte, Crop, Velocidade, Junção, Extração de frames, Divisão e Redação de vídeo) e T16–T20 (Normalização, Visualizer, Trim, Canais e Bleep de áudio), garantindo fidelidade de contêineres, aceleração por hardware e operação estritamente local e ilimitada.

---

## 1. Visão Geral e Requisitos

### 1.1 Catálogo de Ferramentas de Vídeo
- **T09 — Trim video (`VideoTrimmer`):** Corte de trecho com `CMTimeRange(start:duration:)`, exportando cópia MP4/MOV com duração exata sem re-encode desnecessário quando possível.
- **T10 — Crop video (`VideoCropper`):** Recorte espacial de proporção (1:1, 9:16, 16:9, livre) utilizando `AVMutableVideoComposition` com matriz de transformação.
- **T11 — Change video speed (`VideoSpeedController`):** Modificação temporal de 0.25x a 4.0x via `AVMutableComposition.scaleTimeRange`, com algoritmo de preservação de pitch para trilha de áudio (`AVAudioTimePitchAlgorithm.spectral`). Suporte a vídeos mudos.
- **T12 — Join videos (`VideoJoiner`):** Concatenação sequencial de múltiplos clipes compatíveis em um único arquivo MP4, padronizando dimensões de canvas com letterbox se proporções variarem.
- **T13 — Save video frames (`VideoFrameExtractor`):** Extração de quadros individuais em resolução nativa via `AVAssetImageGenerator` em pontos de tempo determinados, exportando PNGs identificados por timecode.
- **T14 — Split video (`VideoSplitter`):** Divisão de clipe em N partes iguais ou marcas específicas, gerando arquivos `part-001.mp4`, `part-002.mp4` em subpasta de destino.
- **T15 — Redact video (`VideoRedactor`):** Aplicação de tarjas pretas sólidas em coordenadas fixas durante intervalos de tempo via camada de composição `CALayer` / `AVVideoCompositionCoreAnimationTool`.

### 1.2 Catálogo de Ferramentas de Áudio
- **T16 — Normalize volume (`AudioNormalizer`):** Varredura de amostras PCM para cálculo de True Peak e aplicação de ganho linear seguro, elevando o volume até -1.0 dBFS sem clipping.
- **T17 — Create audio visualizer (`AudioVisualizer`):** Geração de clipe de vídeo MP4 contendo trilha de áudio e forma de onda animada ou estática renderizada sobre fundo sólido.
- **T18 — Trim audio (`AudioTrimmer`):** Corte de arquivo de áudio por timecode e remoção de silêncio leading/trailing via detecção de threshold de amplitude em dB.
- **T19 — Convert audio channels (`AudioChannelConverter`):** Conversão estéreo para mono (downmix 0.5 L + 0.5 R) e mono para estéreo (duplicação de canal).
- **T20 — Bleep audio (`AudioBleeper`):** Injeção de tom senoidal de 1000 Hz com envelope suave (fade de 5ms) substituindo os samples do áudio original nos intervalos marcados.

### 1.3 Conversão de Mídia e Extração
- Transcodificação de vídeo: MOV ↔ MP4 com presets balanceados e de alta qualidade (`AVAssetExportPresetHighestQuality`, `AVAssetExportPreset1920x1080`).
- Extração de áudio de vídeos: extração da trilha sonora para M4A/AAC ou WAV sem perda.
- Conversão de áudio: WAV, AIFF, M4A/AAC com sample rates nativos (44.1 kHz, 48 kHz).

---

## 2. Arquitetura dos Módulos

```text
Sources/OrbitDropKit/
├── Engines/Video/
│   ├── VideoTranscoder.swift
│   ├── VideoTrimmer.swift
│   ├── VideoCropper.swift
│   ├── VideoSpeedController.swift
│   ├── VideoJoiner.swift
│   ├── VideoFrameExtractor.swift
│   ├── VideoSplitter.swift
│   └── VideoRedactor.swift
└── Engines/Audio/
    ├── AudioTranscoder.swift
    ├── AudioNormalizer.swift
    ├── AudioVisualizer.swift
    ├── AudioTrimmer.swift
    ├── AudioChannelConverter.swift
    └── AudioBleeper.swift
```

---

## 3. Testes Automatizados e Critérios de Aceite
1. **`AudioEngineTests`**:
   - Criação programática de arquivo WAV sintético (1 segundo, 44.1 kHz, estéreo, senoide de 440 Hz).
   - Normalização com `AudioNormalizer`: verificação de pico máximo <= -1.0 dBFS.
   - Conversão de canais com `AudioChannelConverter`: validação de `channelCount == 1`.
   - Bleep com `AudioBleeper`: verificação de amplitude tonal no trecho afetado.
   - Trim com `AudioTrimmer`: validação de duração reduzida.
2. **`VideoEngineTests`**:
   - Criação de clipe sintético MP4/MOV curto (1 a 2 segundos) via `AVAssetWriter`.
   - `VideoTrimmer`: corte para 0.5s e validação de duração com `AVURLAsset`.
   - `VideoFrameExtractor`: extração de frame em t=0.5s e validação de imagem PNG gerada.
   - `VideoSpeedController`: aceleração 2x e conferência de redução de duração pela metade.
   - `VideoJoiner`: concatenação de 2 clipes sintéticos de 1s gerando saída de 2s.
