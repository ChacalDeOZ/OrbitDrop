<div align="center">

# 🪐 OrbitDrop

### O Conversor e Manipulador Nativo de Arquivos Definitivo para macOS.
**100% Offline • Sem Paywalls • Sem Assinaturas • Conversões e Lotes Ilimitados**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-007ACC?style=for-the-badge)](https://apple.com)
[![CI](https://github.com/ChacalDeOZ/OrbitDrop/actions/workflows/ci.yml/badge.svg)](https://github.com/ChacalDeOZ/OrbitDrop/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/Tests-102%20passing-brightgreen?style=for-the-badge)](https://github.com/ChacalDeOZ/OrbitDrop)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/ChacalDeOZ/OrbitDrop?style=for-the-badge&color=gold)](https://github.com/ChacalDeOZ/OrbitDrop/stargazers)

<br/>

<p align="center">
  <b>Arraste qualquer arquivo no Finder, aperte uma tecla modificadora e converta, edite ou compartilhe num piscar de olhos.</b><br/>
  Um menu radial ultra-rápido surge sob o cursor com Glassmorphism refinado, zero latência e total privacidade.
</p>

---

</div>

## 💡 Por que o OrbitDrop?

Outros conversores cobram assinaturas caras, exigem upload dos seus dados para a nuvem ou impõem limites abusivos de 20 arquivos. 

**O OrbitDrop foi criado para ser diferente:**
- 🚫 **Zero Limitações:** Converta 1, 20, 100 ou 10.000 arquivos. Nunca haverá paywall, trial ou contadores.
- 🔒 **100% Offline & Privado:** Seus dados nunca saem da sua máquina. Zero telemetria, zero servidores, sem permissões de rede.
- ⚡ **Desempenho Apple Silicon:** Renderização e transcodificação aceleradas por hardware usando `ImageIO`, `CoreImage`, `AVFoundation` e `Apple Vision`.
- 🛡️ **Preservação Sagrada:** O arquivo original **nunca** é modificado. Cópias novas são salvas atomicamente com resolução de nomes sem colisão (`-converted`, `-2`).

---

## ✨ Três Modos de Ação Direto no Cursor

Arraste arquivos ou pastas no Finder e pressione uma tecla para abrir a roda radial correspondente:

| Tecla | Modo | O que faz |
| :---: | :---: | :--- |
| <kbd>⇧ Shift</kbd> | **Conversão** | Converte dinamicamente formatos comuns (PNG, JPEG, HEIC, TIFF, BMP, WebP, AVIF, PDF, MP4, MOV, WAV, M4A, ZIP, TAR, TAR.GZ, etc.). |
| <kbd>⌘ Command</kbd> | **Ferramentas** | Acesso contextual a 24+ utilitários de edição, OCR local, redação de privacidade, cortes, normalização e metadados com paginação inteligente. |
| <kbd>⌃ Control</kbd> | **Ações Rápidas** | Dispara ações nativas instantâneas: AirDrop, Prateleira Flutuante, Copiar no Finder, Mover, Copiar Caminho e Abrir Terminal. |

---

## 🛠️ Catálogo Completo de Ferramentas (24 Ferramentas Nativas)

<details open>
<summary><b>📸 Imagens & Privacidade</b></summary>
<br/>

- **T01 Comprimir Imagem:** Redução inteligente de tamanho por busca iterativa com teto de bytes e downsampling.
- **T02 Expurgo de Metadados:** Remoção completa e irreversível de tags EXIF, dados de GPS e comentários de lente.
- **T03 Ajustes de Foto:** Exposição, contraste, saturação e brilho acelerados por CoreImage respeitando orientação EXIF.
- **T04 Anotações:** Desenho de retângulos, setas com ponta geométrica e textos gravados no bitmap.
- **T05 Adicionar Fundo:** Expansão de canvas com moldura sólida/gradiente, padding e cantos arredondados.
- **T06 Corte de Imagem:** Recorte espacial de proporções (1:1, 4:3, 16:9, livre) em pixels exatos.
- **T07 Redação com Apple Vision:** Detecção local de rostos e queima de tarjas pretas sólidas opacas (`RGB 0,0,0`) sem vazamento.
- **T08 Criar Colagem:** Junção inteligente de múltiplas fotos em mosaico com centralização vertical automática.
- **T24 Leitor de QR Code:** Detecção e leitura local via Vision sem abrir links perigosos automaticamente.
- **Fotos para PDF:** Consolidação de múltiplas imagens heterogêneas em 1 PDF único (1 página por foto).
</details>

<details open>
<summary><b>🎬 Vídeo & Áudio</b></summary>
<br/>

- **T09 Cortar Vídeo:** Trim com precisão cirúrgica de timecode sem perda de sincronia.
- **T10 Crop de Vídeo:** Corte espacial aplicando rotação de metadados (`preferredTransform`).
- **T11 Acelerar Vídeo:** Mudança de velocidade (0.25x até 4.0x) com preservação espectral de pitch na voz.
- **T12 Juntar Vídeos:** Concatenação contínua de clipes em MP4 com ponte de gaps de áudio.
- **T13 Salvar Frames:** Extração de quadros em PNG lossless de alta resolução.
- **T14 Dividir Vídeo:** Divisão de clipes em N partes com nomenclatura sequencial padronizada.
- **T15 Redigir Vídeo:** Máscara retangular opaca sobreposta diretamente nas faixas de vídeo.
- **T16 Normalizar Áudio:** Ganho linear elevando pico máximo até -1.0 dBFS sem clipping.
- **T17 Audio Visualizer:** Criação de vídeo MP4 com forma de onda animada sincronizada ao som.
- **T18 Cortar Áudio:** Trim de amostras PCM com fade suave para evitar estalos.
- **T19 Converter Canais:** Downmix estéreo para mono (50/50) ou mono para estéreo.
- **T20 Bleep de Censura:** Injeção de tom senoidal de 1000 Hz com envelope suave de 5ms.
</details>

<details open>
<summary><b>📄 PDF, OCR, Legendas & Compactados</b></summary>
<br/>

- **T21 Juntar PDFs:** Mescla de múltiplos documentos preservando dimensões e orientação das páginas.
- **T22 Organizar Páginas:** Rotação (±90°), reordenação, exclusão e duplicação com cópia profunda.
- **T23 Dividir PDF:** Separação página por página (`-page-001.pdf`) com resolução de conflitos.
- **Render 300 DPI:** Exportação de páginas de PDF para imagens nítidas prontas para impressão.
- **OCR Local com Apple Vision:** Reconhecimento de texto óptico offline de alta precisão para imagens e PDFs escaneados diretamente para Markdown estruturado.
- **Extração de Texto e Conversor Markdown:** Conversão de PDF, HTML, RTF, JSON, código fonte e texto para Markdown (`.md`) formatado.
- **Conversor de Legendas:** Conversão bidirecional SRT ↔ VTT com ajuste de timestamps.
- **Compactação Segura (ZIP / TAR / TAR.GZ):** Criação e extração via utilitários nativos (`/usr/bin/ditto` e `/usr/bin/tar`) com proteção estrita contra path traversal (`../`) e zip bombs.
</details>

<details open>
<summary><b>⚡ 6 Ações de Arquivo de Sistema</b></summary>
<br/>

- **A01 AirDrop:** Envio nativo imediato pelo seletor de compartilhamento do macOS.
- **A02 Float Shelf:** Prateleira flutuante persistente para reter arquivos temporariamente entre Spaces com drag-in e drag-out.
- **A03 Copiar:** Registra arquivos no clipboard do Finder prontos para colar com <kbd>⌘ Command</kbd> + <kbd>V</kbd>.
- **A04 Mover:** Movimentação atômica com confirmação de destino e proteção contra sobrescrita.
- **A05 Copiar Caminho:** Caminhos absolutos limpos em UTF-8 copiados para a área de transferência.
- **A06 Terminal / iTerm2:** Abertura direta do diretório no terminal com proteção total contra injeção de shell.
</details>

---

## 🎛️ Experiência de Uso Contextual & Interativa

- **Roda Radial Paginada Contextual:** Abertura inteligente filtrando apenas ferramentas compatíveis com os arquivos arrastados (`ToolRegistry`). Máximo de 8 setores por tela com navegação contínua ("◀ Anterior" / "▶ Mais") sem sobrecarga cognitiva.
- **HUD Interativo de Parâmetros:** Ajuste de valores antes da execução via controles deslizantes e seletores (velocidade de vídeo, teto de compressão em KB, recorte de foto, rotação de páginas).
- **HUD Flutuante de Progresso:** Feedback visual em tempo real com barra de progresso, percentual, nome do arquivo em processamento e botão cooperativo de cancelamento para lotes pesados.
- **CI Automatizado via GitHub Actions:** Suíte completa de testes e validação de build a cada push e pull request.

---

## 🚀 Como Compilar e Rodar

### Pré-requisitos
- Mac com Apple Silicon (M1, M2, M3, M4 ou superior).
- macOS 13.0 (Ventura) ou superior.
- Xcode 16+ ou Command Line Tools instalados (`xcode-select --install`).

### 1. Clonar o Repositório
```bash
git clone https://github.com/ChacalDeOZ/OrbitDrop.git
cd OrbitDrop
```

### 2. Rodar a Suíte de Testes (102 testes unitários e de integração)
```bash
swift test
```

### 3. Compilar e Gerar o App Assinado
```bash
./Scripts/build_app.sh
```
O bundle pronto para uso será criado em `build/OrbitDrop.app`.

### 4. Iniciar o Aplicativo
```bash
open build/OrbitDrop.app
```

---

## ♿ Acessibilidade e Teclado

O OrbitDrop foi projetado para ser 100% acessível:
- **Navegação por Teclado:** Use as setas <kbd>←</kbd> <kbd>→</kbd> <kbd>↑</kbd> <kbd>↓</kbd> ou <kbd>,</kbd> / <kbd>.</kbd> para navegar entre os setores da roda radial e páginas, <kbd>Enter</kbd> para selecionar e <kbd>Esc</kbd> para fechar.
- **VoiceOver:** Compatibilidade integral com elementos de botão anunciados pelo VoiceOver e acionamento via <kbd>VO</kbd> + <kbd>Space</kbd>.
- **Reduce Motion:** Respeito automático às preferências de redução de movimento do sistema.

---

## 📦 Estrutura de Arquitetura

```text
OrbitDrop/
├── .github/workflows/          # Automação CI/CD (GitHub Actions para build e testes)
├── Sources/
│   ├── OrbitDropApp/           # Processo residente na barra de menus (AppDelegate, main)
│   └── OrbitDropKit/           # Framework central desacoplado e testável
│       ├── Models/             # Modelos imutáveis Sendable (FileDescriptor, RadialItem)
│       ├── Radial/             # Geometria trigonométrica pura e hit-testing
│       ├── Drag/               # Monitores de teclas, detecção de arrasto e DragPayloadProbe
│       ├── FormatRegistry/     # Grafo declarativo de formatos e ToolRegistry contextual
│       ├── Jobs/               # Ator Swift 6 para processamento concorrente em background
│       ├── Engines/            # Motores de Imagem, Áudio, Vídeo, PDF, Markdown e Compactados
│       ├── Actions/            # Despachantes das 6 ações de arquivo de sistema
│       ├── Vision/             # Detecção de rostos, leitor de QR Code e OCRProcessor offline
│       ├── Onboarding/         # Fluxo nativo de boas-vindas em 5 passos
│       ├── Settings/           # Preferências persistidas thread-safe
│       └── UI/                 # Menus radiais paginados, Float Shelf, HUD de Parâmetros e HUD de Progresso
└── Tests/                      # 102 testes automatizados cobrindo todos os fluxos
```

---

## 🤝 Contribuições

Contribuições são muito bem-vindas! Se você deseja adicionar suporte a novos formatos, sugerir melhorias de UX ou reportar problemas:
1. Faça um Fork do projeto.
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`).
3. Commit suas alterações (`git commit -m 'feat: minha nova feature'`).
4. Faça o Push (`git push origin feature/MinhaFeature`).
5. Abra um Pull Request.

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações.

<div align="center">

Feito com dedicação por [Danilo Chacal (ChacalDeOZ)](https://github.com/ChacalDeOZ) 🚀

</div>
