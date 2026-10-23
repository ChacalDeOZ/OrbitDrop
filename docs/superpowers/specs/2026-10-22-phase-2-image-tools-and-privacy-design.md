# Especificação Técnica — OrbitDrop: Fase 2 (Ferramentas de Imagem, Privacidade e Visão Local)

**Data:** 2026-10-22  
**Status:** Aprovado para Planejamento  
**Objetivo:** Implementar o catálogo completo de ferramentas de imagem e privacidade: T01 (Compressão inteligente), T02 (Edição/remoção de metadados), T03–T08 (Ajustes, Anotação, Fundo, Corte, Redação local via Apple Vision, Colagem), T24 (Leitura local de QR codes) e conversão de múltiplas imagens selecionadas para documento PDF consolidado.

---

## 1. Visão Geral e Requisitos

### 1.1 Escopo da Fase 2
1. **T01 — Compressão Inteligente (`ImageCompressor`):**
   - Estratégia por tamanho-alvo (MB), redução percentual ou preset (leve, equilibrado, agressivo).
   - Busca binária de fator de compressão com limite de 5 iterações para evitar overhead.
   - Redimensionamento proporcional (downsampling) seguro quando o tamanho exigido for menor que o limite do codec.
   - Geração de nova cópia com convenção `-compressed.ext`.

2. **T02 — Metadados e Privacidade (`MetadataEditor`):**
   - Inspeção de dicionários EXIF, GPS e IPTC via `CGImageSourceCopyPropertiesAtIndex`.
   - Remoção completa ou seletiva de localização geográfica, autor, modelo de câmera e carimbo de data.
   - Verificação pós-salvamento: teste automatizado atesta que a nova cópia não retém nenhum metadado privado.

3. **T03 — Ajustes Finos de Foto (`ImageAdjustments`):**
   - Pipeline de processamento via CoreImage: exposição (`CIExposureAdjust`), contraste/brilho/saturação (`CIColorControls`), temperatura/matiz (`CITemperatureAndTint`).
   - Renderização via `CIContext` acelerado por Metal para bitmap de saída.

4. **T04 — Anotações em Fotos (`ImageAnnotator`):**
   - Aplicação de caixas retangulares, setas direcionais, texto com fundo e marca-texto (highlight).
   - Rasterização definitiva na cópia de saída.

5. **T05 — Adicionar Fundo e Moldura (`ImageBackgroundAdder`):**
   - Moldura com cor sólida ou gradiente, proporções padrão (1:1, 4:5, 16:9, livre), padding configurável e cantos arredondados.
   - Aplicação de sombra suave opcional ao redor da imagem principal.

6. **T06 — Corte de Imagens (`ImageCropper`):**
   - Corte por aspecto pré-definido (1:1, 4:3, 16:9) e corte livre em coordenadas de pixels absolutas.
   - Suporte a corte centralizado em lote com âncora fixa.

7. **T07 — Redação Local e Anonimização (`ImageRedactor`):**
   - Detecção automática local via Apple Vision framework: `VNDetectFaceRectanglesRequest` (rostos) e `VNRecognizeTextRequest` (textos sensíveis).
   - Aplicação de tarjas retangulares opacas pretas puras (`RGB 0,0,0`) com substituição de pixels destrutiva irreversível (sem soft blur vazável).

8. **T08 — Montagem de Colagem (`ImageCollageBuilder`):**
   - Junção em grade (grid 2x2, linha, coluna) de 2 a N imagens selecionadas, equalizando dimensões e margens internas em um único arquivo de saída.

9. **T24 — Leitura Local de QR Code (`QRCodeReader`):**
   - Detecção e leitura estritamente local usando `VNDetectBarcodesRequest` (`symbology: .qr`).
   - Retorno dos dados decodificados em formato texto limpo, sem execução de links externos ou conexões automáticas de rede.

10. **Multi-imagem para PDF (`ImageToPDFConverter`):**
    - Conversão direta de múltiplas fotos (PNG, JPG, HEIC, TIFF) em um documento PDF único, onde cada foto ocupa 1 página na resolução original.

---

## 2. Arquitetura dos Módulos

```text
Sources/OrbitDropKit/
├── Engines/Images/
│   ├── ImageCompressor.swift
│   ├── MetadataEditor.swift
│   ├── ImageAdjustments.swift
│   ├── ImageCropper.swift
│   ├── ImageBackgroundAdder.swift
│   ├── ImageAnnotator.swift
│   ├── ImageCollageBuilder.swift
│   └── ImageToPDFConverter.swift
├── Vision/
│   ├── ImageRedactor.swift
│   └── QRCodeReader.swift
└── UI/Editors/
    └── PhotoEditorWindowController.swift
```

---

## 3. Testes Automatizados e Critérios de Aceite
1. **`MetadataEditorTests`**: injeção de GPS em fixture de imagem, remoção via `MetadataEditor` e assert de ausência total de chaves geográficas.
2. **`ImageCompressorTests`**: compressão de imagem de alta densidade com validação de que os bytes finais são inferiores ao original e o arquivo permanece válido.
3. **`ImageRedactorTests`**: redação de região com assert em nível de pixel confirmando preenchimento sólido preto sem vazamento de informação.
4. **`ImageToPDFTests`**: conversão de 3 imagens sintéticas em arquivo PDF e conferência de 3 páginas via `PDFDocument`.
5. **`QRCodeTests`**: geração de QR Code sintético via CoreImage, leitura via `QRCodeReader` e assert de equivalência exata da string original.
6. **`ImageCollageTests`**: combinação de 2 fotos 64x64 em grid gerando 1 arquivo 128x64 ou 64x128.
