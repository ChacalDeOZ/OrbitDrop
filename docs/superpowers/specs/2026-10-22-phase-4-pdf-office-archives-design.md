# Especificação Técnica — OrbitDrop: Fase 4 (PDF, Documentos, Legendas e Compactados)

**Data:** 2026-10-22  
**Status:** Aprovado para Planejamento  
**Objetivo:** Implementar os motores de PDF da Fase 4: T21 (Merge PDFs), T22 (Organize PDF pages), T23 (Split PDFs), renderização de páginas a 300 DPI, extração de texto para TXT/Markdown, conversor de legendas (SRT ↔ VTT) e processamento seguro de arquivos compactados (ZIP, TAR, GZ) com proteção contra path traversal e zip bombs.

---

## 1. Visão Geral e Requisitos

### 1.1 Catálogo de Ferramentas de PDF (PDFKit Nativo)
- **T21 — Merge PDFs (`PDFMerger`):** Concatena múltiplos arquivos PDF preservando anotações, orientação e dimensões de página individuais.
- **T22 — Organize PDF pages (`PDFPageOrganizer`):** Permite rotação de páginas em múltiplos de 90° (`page.rotation`), reordenação e exclusão de páginas específicas.
- **T23 — Split PDFs (`PDFSplitter`):** Divide um documento PDF em arquivos individuais de 1 página ou em conjuntos baseados em intervalos especificados (ex: "1-3, 5, 7-9").
- **Renderização a 300 DPI (`PDFRasterizer`):** Renderiza páginas de PDF para arquivos PNG ou JPEG a 300 DPI nominais utilizando a escala `300.0 / 72.0` sobre a caixa de corte da página.
- **Extração de Texto (`PDFTextExtractor`):** Extrai o conteúdo textual de cada página do PDF preservando quebras de linha e formatando em texto simples (`.txt`) ou Markdown estruturado (`.md`).

### 1.2 Conversor de Legendas (`SubtitleConverter`)
- Conversão bidirecional entre SRT e VTT.
- SRT: formatação de tempo com vírgula para milissegundos (`00:01:20,500 --> 00:01:23,800`).
- VTT: cabeçalho obrigatório `WEBVTT` e ponto para milissegundos (`00:01:20.500 --> 00:01:23.800`).
- Suporte a Unicode UTF-8 e preservação de blocos e números de sequência.

### 1.3 Compactação e Descompactação Segura (`ArchiveProcessor`)
- Compactação de arquivos e pastas para `.zip` via `NSFileCoordinator` / `FileManager` nativos.
- Extração de `.zip`, `.tar` e `.tar.gz`.
- **Segurança Mandatória:**
  - Bloqueio imediato de arquivos cujo caminho contenha `../` ou inicie com barra `/` absoluta.
  - Bloqueio de descompactação que exceda cotas de tamanho seguro (limite de 1 GB e 50.000 arquivos).

---

## 2. Arquitetura dos Módulos

```text
Sources/OrbitDropKit/
├── Engines/PDF/
│   ├── PDFMerger.swift
│   ├── PDFPageOrganizer.swift
│   ├── PDFSplitter.swift
│   ├── PDFRasterizer.swift
│   └── PDFTextExtractor.swift
├── Engines/Subtitles/
│   └── SubtitleConverter.swift
└── Engines/Archives/
    └── ArchiveProcessor.swift
```

---

## 3. Testes Automatizados e Critérios de Aceite
1. **`PDFEngineTests`**:
   - Criação de PDF sintético multipágina programático.
   - `PDFMerger`: merge de 2 documentos gerando documento consolidado com a soma das páginas.
   - `PDFSplitter`: divisão em arquivos individuais.
   - `PDFPageOrganizer`: rotação em 90° e remoção de página.
   - `PDFRasterizer`: conferência de dimensões em pixels da imagem gerada a 300 DPI.
   - `PDFTextExtractor`: extração de texto preservando strings inseridas.
2. **`SubtitleTests`**:
   - Conversão SRT para VTT validando cabeçalho `WEBVTT` e pontos nos timestamps.
   - Conversão VTT para SRT validando vírgulas nos timestamps.
3. **`ArchiveSecurityTests`**:
   - Compactação e descompactação de diretório com validação de conteúdo.
   - Rejeição garantida de arquivo malicioso com path traversal (`../escaped.txt`).
