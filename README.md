# OrbitDrop

> Conversor e manipulador nativo de arquivos para macOS — 100% offline, local e ilimitado.

OrbitDrop é uma aplicação nativa construída em Swift 6 e AppKit para macOS (Apple Silicon M1+), permitindo converter imagens, manipular documentos e realizar ações contextuais de arquivos diretamente durante o gesto de arrastar e soltar (drag & drop), ou através de uma drop zone flutuante.

---

## Diferenciais Inegociáveis
- **Uso Ilimitado:** Sem limite de 20 arquivos, sem contador de conversões, sem paywall e sem assinaturas.
- **100% Offline:** Todas as operações ocorrem diretamente no seu Mac via aceleradores nativos de hardware da Apple (ImageIO, CoreGraphics, AVFoundation).
- **Preservação de Dados:** Arquivos originais nunca são modificados ou sobrescritos; os resultados são gerados como novas cópias com nomes resolvidos atomicamente.

---

## Como Compilar e Testar

### Requisitos
- macOS 13 (Ventura) ou superior (testado em macOS 27 no Apple Silicon arm64).
- Xcode 16+ ou linha de comando do Swift (`swift --version`).

### 1. Executar os Testes Automatizados
```bash
swift test
```
A suíte executa testes de geometria radial, escrita atômica, pipeline nativo de imagens e a prova de 105 conversões consecutivas sem paywall.

### 2. Compilar e Executar em Modo Debug
```bash
swift run OrbitDropApp
```

### 3. Empacotar o Aplicativo (.app assinado)
```bash
./Scripts/build_app.sh
```
O aplicativo pronto para uso será gerado em `build/OrbitDrop.app`.

---

## Como Utilizar
1. Ao iniciar, o ícone do **OrbitDrop** aparecerá na sua barra de menus.
2. **Método 1 (Arrasto + Tecla):** No Finder, comece a arrastar um arquivo de imagem (PNG, TIFF, BMP, HEIC) e toque na tecla `Shift`. O menu radial se abrirá ao redor do cursor. Solte o arquivo sobre o setor `JPEG`. O arquivo convertido será criado ao lado do original e revelado no Finder.
3. **Método 2 (Drop Zone Flutuante):** Clique no ícone da barra de menus e selecione **"Abrir Drop Zone Flutuante"**. Uma janela flutuante surgirá na tela permitindo arrastar e soltar arquivos a qualquer momento, sem necessidade de permissões globais do sistema.
4. **Permissões:** Para que o macOS permita detectar a tecla `Shift` enquanto você arrasta arquivos de outros aplicativos (como o Finder), conceda acesso em:
   *Ajustes do Sistema > Privacidade e Segurança > Acessibilidade > OrbitDrop*.

---

## Licença
Código original independente, desenvolvido sob licença livre e sem utilização de ativos, marcas ou código de terceiros.
