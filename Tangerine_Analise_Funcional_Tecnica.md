# Tangerine for Mac — análise funcional e especificação para produto equivalente

**Pesquisa em 22/10/2026 | Idioma: pt-BR | Escopo: macOS nativo**

> **Objetivo:** documentar as capacidades publicamente conhecidas do Tangerine for Mac para orientar o desenvolvimento de um **produto independente com funcionalidades equivalentes**, sem copiar nome, identidade visual, textos proprietários, código ou ativos do concorrente.
>
> **Rigor:** `[CONFIRMADO]` é descrição publicada pelo site, desenvolvedor ou App Store; `[INFERIDO]` é hipótese plausível ainda não validada usando o binário; `[PROPOSTO]` é decisão de produto/engenharia para a réplica funcional. Não foram instalados nem inspecionados o binário, seus recursos internos ou seu tráfego.
>
> **DECISÃO DO PRODUTO DO DANILO:** o aplicativo a desenvolver terá **uso ilimitado desde a instalação**, sem franquia de 20 arquivos, contador, trial, paywall, assinatura ou bloqueio de conversões/ferramentas. O trial descrito abaixo é **apenas um fato histórico/comercial do Tangerine original**, não requisito para a nova aplicação.

## 1. Resumo executivo

Tangerine é um utilitário macOS de conversão, edição e manipulação de arquivos **no contexto do cursor durante o arrastar e soltar**, com três menus radiais. Pretende evitar abrir separadamente um conversor, selecionar arquivos e navegar por diálogos para operações rotineiras. Toda conversão/edição ocorre localmente; os arquivos originais são preservados nas operações de processamento. [CONFIRMADO: F1, F2, F3]

| Item | Situação pública em 22/10/2026 | Evidência |
|---|---|---|
| Plataforma | Mac com Apple silicon M1 ou superior, macOS 13+ | F1, F4 |
| Interface | App residente na barra de menus; roda sem janela principal obrigatória | F4 |
| Atalho de conversão | Arrastar arquivo e tocar `Shift` | F1, F2 |
| Atalho de ferramentas | Arrastar e tocar `Command` | F1, F2, F5 |
| Atalho de ações | Arrastar e tocar `Control` | F1, F2 |
| Comportamento do menu | Roda aparece perto do cursor e permanece após soltar a tecla; soltar o arquivo em uma opção executa | F1, F2 |
| Catálogo anunciado | **275 opções de conversão, 26 ferramentas e 6 ações** | F1 |
| Dados | Processamento local, sem enviar conteúdos/nomes dos arquivos ao desenvolvedor; sem analytics, publicidade ou rastreadores segundo a política | F3 |
| Resultado | Nova cópia ao lado do original; janela pequena de progresso; revelar no Finder ao concluir | F2, F4 |
| Lotes | Seleção múltipla; inclusive mistura de formatos compatíveis com o mesmo destino | F2, F4, F5 |
| Trial do concorrente (não replicar) | Primeiros **20 arquivos** gratuitos; menu de ações gratuito | F4, F5 |
| Compra do concorrente (não replicar) | Desbloqueio único de **US$ 29,99** na App Store americana; sem assinatura | F4, F5 |
| Modelo do produto a desenvolver | **Conversões, edições e ações sem qualquer limite por quantidade de arquivos** | Decisão do projeto |
| Versão | **2.0.1** na App Store; kit de imprensa ainda descreve 1.4 | F2, F4 |

**Limite relevante da pesquisa:** o site afirma 26 ferramentas, mas a página pública `/tools` expõe descrições individuais de **22**; a descrição da App Store acrescenta explicitamente **leitura de QR code** e **divisão de PDF**, sem enumerar as outras duas possíveis diferenças de contagem. Assim, **não é correto inventar a lista completa de 26**. A versão mais atual deve ser confirmada com teste manual do app. Também **não foi encontrada uma matriz pública das 275 rotas individuais**. [F1, F4, F6]

## 2. Inventário das páginas e das evidências

- **Home / Features:** proposta, menus, total de recursos, formatos, privacidade e atalho interativo simulado. F1.
- **Página Tools:** catálogo individual, descrições e capturas de interfaces avançadas; ferramenta com possíveis dados dinâmicos. F6.
- **Press kit:** funcionamento, versão histórica, data de lançamento em 07/09/2026, imagens de rodas e ferramentas. F2.
- **Privacy:** armazenamento, acesso a diretórios e ausência de rastreamento segundo o editor. F3.
- **Mac App Store:** versão atual, requisitos, compras, trial, ações, funcionalidades adicionais e changelog. F4.
- **Publicação do desenvolvedor:** complementa funcionamento em Finder, Desktop, outras origens e preço; alega menu Actions sempre gratuito. F5.

O site não fornece especificação de arquitetura, algoritmos, formato de banco, licenciamento interno, codecs empacotados, tratamento de erro de cada formato, resultados de OCR ou contrato de acessibilidade. Essas decisões abaixo são recomendações técnicas, nunca alegações de implementação interna do Tangerine.

## 3. Interação principal: os três menus radiais

### 3.1 Conversão (`Shift`) [CONFIRMADO]

1. Usuário seleciona um ou vários arquivos no Finder/Área de Trabalho (ou origem capaz de oferecer arquivos locais).
2. Começa a arrastá-los com o mouse/trackpad.
3. Toca `Shift` durante o drag; aparece uma roda de formatos ao redor/próximo ao ponteiro.
4. A roda lista apenas destinos aplicáveis ao conjunto arrastado.
5. Usuário pode soltar a tecla; a roda continua aberta enquanto o arrasto prossegue.
6. Solta o conteúdo sobre um setor de destino (ex.: `.png`).
7. O app processa localmente, informa progresso e escreve resultado ao lado dos originais, sem sobrescrevê-los.
8. No fim, disponibiliza resultado no Finder.

**Detalhes de comportamento a especificar no produto:** ativação com um toque vs tecla mantida; raio angular variável; quantas opções por anel; páginas de opções; ícones dos formatos; fallback se não houver formato comum; teclado; sombras; posicionamento sobre notch, Dock e múltiplos monitores. Estes aspectos finos não constam de documentação técnica publicada e devem ser tratados como `[PROPOSTO]`.

### 3.2 Ferramentas contextuais (`Command`) [CONFIRMADO]

O usuário arrasta um arquivo, toca `Command` e vê somente operações pertinentes ao tipo: foto → edição/corte/anotações; vídeo → corte/velocidade; áudio → normalização/trim; PDF → páginas; seleção múltipla → operações em lote disponíveis. Algumas operações abrem janelas nativas de edição com prévia e controles. A descrição da App Store ainda diz `Option+Shift`, atalho de release anterior; a Home atual e o changelog de 2.0 usam `Command`. Deve haver atalhos configuráveis. [F1, F4, F5]

### 3.3 Ações de arquivo (`Control`) [CONFIRMADO]

Menu independente de conversores, funciona com arquivos, pastas, seleções de tipos variados e itens sem operação de conversão. As seis ações são AirDrop, Float, Copy, Move, Copy Path e Terminal. Não gastam franquia gratuita. [F1, F2, F5]

### 3.4 Estados e transições [PROPOSTO]

| Estado | Entrada | Feedback | Saída |
|---|---|---|---|
| `idle` | app em espera | apenas item no menu bar | detectar candidato |
| `dragCandidate` | botão down + movimento inicial | nenhum overlay até arquivo ser reconhecido | drag válido / reset |
| `dragActive` | arrasto de arquivo local reconhecido | leve indicação opcional | Shift/Command/Control |
| `radialOpen` | atalho acionado | roda ancorada ao ponteiro, sticky | mudar modo / soltar / Esc |
| `radialHover` | ponteiro num setor válido | animação + descrição + confirmação | soltar |
| `preflight` | soltura | verifica formato, pasta e permissões; **não verifica cota** | job / erro |
| `processing` | job enfileirado | progresso, etapa, botão cancelar | sucesso/falha |
| `completed` | saída comprometida no disco | notificação e revelar no Finder | idle |
| `cancelled` | Esc, soltar fora, usuário cancela | nenhuma alteração no original | idle |

**Desafio crítico de viabilidade:** `NSEvent.addGlobalMonitorForEvents` observa eventos de outros apps mas não assume/transforma o drag nem concede, por si só, acesso ao payload de Finder. A captura universal do item arrastado e o drop sobre uma sobreposição própria dependem do mecanismo de arraste, do sandbox e da origem. Exige **prova de conceito em macOS real antes de prometer equivalência total**. Suportar alternativa por drop-zone, serviços/Finder Quick Action e seletor de arquivo. Referências Apple: A1–A3.

## 4. Matriz de formatos publicados

**Atenção:** os grupos abaixo são **formatos conhecidos, não todos os pares de conversão**. Não assumir `N × N`: certas rotas são só entrada ou só saída, e alguns containers/codecs exigem transcodificação. Registrar suporte por `sourceUTType/sourceExt -> targetExt`, perfil, confiabilidade e engine.

| Família | Formatos anunciados | Regras declaradas |
|---|---|---|
| Imagens | JPG/JPEG, PNG, WebP, HEIC, TIFF, AVIF, BMP | SVG é somente entrada; PDF pode ser exportado; GIF aparece em listagem da App Store e no grupo vídeo da Home |
| Áudio | MP3, M4A, WAV, FLAC, OGG, Opus, AIFF, WMA | WMA consta na Home, não em lista reduzida da App Store |
| Vídeo | MP4, MOV, MKV, WebM, AVI, WMV, GIF | exportação MP3 do áudio de vídeo |
| PDF | origem PDF → DOCX, PAGES, PPTX, XLSX, JPG, PNG, EPUB, TXT, MD | Home descreve exportação de todas as páginas e imagens a 300 DPI; qualidade semântica de DOCX/PPTX/XLSX não detalhada |
| Documentos | DOCX, PAGES, Markdown/MD, TXT, EPUB | RTF, RTFD e clippings de texto são entradas; HTML é saída |
| Slides | PPT e PPTX, PDF, JPG, PNG | PPT é apenas entrada; PDF → PPTX indicado na Home |
| Planilhas | XLSX, ODS, CSV, TSV | XLS só entrada; PDF saída |
| Legendas | SRT, VTT, TXT | TXT é saída explicitamente mostrada |
| Compactados | ZIP, TAR, GZIP | RAR apenas entrada; converter pode envolver extração e reempacotamento |

### 4.1 Regras de fidelidade por categoria [PROPOSTO]

- **Imagem:** preservar proporção/EXIF/orientação conforme opção; ICC profiles e alpha; tratar HDR e HEIC, conversões 8/16 bits; sinalizar AVIF/WebP animado se não suportado.
- **Vídeo:** diferenciar contêiner de codec; transcode vs remux; controlar H.264/H.265/VP9/AV1 por compatibilidade; preservar áudio/legendas só se suportado; rotação e VFR.
- **Áudio:** frequência, bitrate, canais, sample depth, tags; não prometer FLAC→MP3 sem perda.
- **PDF → imagem:** 1 página por imagem, nomes `documento-p001.png`, DPI configurável (padrão 300 conforme site); PDF com senha pede autorização; PDF→formatos editáveis é conversão complexa que pode perder layout e tabelas.
- **Office/Pages:** requer engine real para ler/escrever estrutura; renderização fiel não é garantida por PDFKit sozinho. Nunca implementar um DOCX falso renomeando TXT/ZIP nem um XLSX renomeando CSV.
- **Arquivos:** TAR e GZIP são coisas distintas; `.tar.gz` é arquivo TAR comprimido; definir arquivamento e extração; prevenir path traversal e zip bombs.
- **Lote misto:** interseção de destinos suportados para todos os itens, ou menu que explicita quais serão ignorados; jamais converter silenciosamente só parte do lote.

### 4.2 Catálogo de capacidades em runtime [PROPOSTO]

Em vez de hardcode publicitário, cada operação tem `id`, `label`, `inputUTTypes`, `outputUTTypes`, `supportsBatch`, `supportsDirectories`, `requiresOptionsUI`, `engine`, `availability`, `warnings` e `estimatedCost`. O menu filtra por conteúdo **realmente implementado/testado**. Um contador de rotas deve ser calculado pelo registro e exibido somente após testes por caminho. A meta de 275 opções é uma meta de paridade de mercado, não uma lista magicamente deduzível.

## 5. Catálogo detalhado de ferramentas

### 5.1 Operações transversais (2 publicadas em `/tools`)

**T01 — Compress [CONFIRMADO]**
- Reduz tamanho preservando origem; suporta imagens, vídeo, áudio, PDF conforme App Store.
- Interface: tamanho-alvo (MB), redução percentual, presets. Imagem pode ser redimensionada ao comprimir; suporta 1 arquivo ou seleção.
- `[PROPOSTO]`: mostrar tamanho original/estimado, qualidade, resolução, codec, limite de tentativas e alerta quando meta é impossível; saída `-compressed`.

**T02 — Edit metadata [CONFIRMADO]**
- Visualiza, pesquisa, modifica e remove metadados incorporados, agrupados por arquivo/faixa/capítulo.
- Foto: campos de câmera/localização/autor; remove GPS e dados internos.
- `[PROPOSTO]`: Exif/IPTC/XMP/ID3, data, título, artista e tags de vídeo/PDF quando a engine permitir; opção “remover tudo”; confirmação de irreversibilidade de informação na cópia; checar pós-exportação.

### 5.2 Imagens (6 publicadas em `/tools`)

**T03 — Edit photos:** editor com preview e controles finos de luz, cor, detalhe; dehaze, clarity, grain, redução de ruído; comparar antes/depois, reset, exportar cópia. `[PROPOSTO]` sliders exposição, contraste, highlights, sombras, temperatura, matiz, saturação, vibrance, nitidez, vinheta e intensidade.

**T04 — Annotate photos:** setas, caixas, círculos, linhas, texto, formas, callouts numerados, lupa, inserir imagem, desenho livre e marca-texto; redimensionar/rotacionar/mover em camadas; undo/redo; exportação raster. Em tela pública aparecem toolbars de edição e canvas.

**T05 — Add a background:** plano de fundo sólido, gradiente ou imagem escolhida; proporção de canvas, padding, cantos arredondados; blur e sombra; prévia; fundos de posts/screenshots e exportação.

**T06 — Crop images:** arrastar crop, proporções comuns/customizadas e dimensões exatas em pixels; preview; lote opcional com regra de ancoragem aplicada a todos os itens.

**T07 — Redact photos:** retângulos movíveis em camadas com preenchimento sólido ou blur; detecção **local** de texto e faces; revisão humana obrigatória; redaction deve alterar pixels exportados (não apenas exibir overlay reversível); teste de privacy burn-in.

**T08 — Create a collage:** seleção múltipla, reordenação; layouts grid, linha, coluna, elemento de destaque; tamanho final, gaps, bordas/cantos/fundo; gerar arquivo único.

### 5.3 Vídeo (7 publicadas em `/tools`)

**T09 — Trim video:** marcar início/fim, navegar quadro a quadro, inserir timecodes precisos, preview; cópia do segmento.

**T10 — Crop video:** reposicionar quadro, proporção/dimensões em pixels, manter áudio original, preview de safe area.

**T11 — Change video speed:** velocidade lenta/rápida; preservar pitch de áudio; funcionar também em vídeo sem faixa de áudio; confirmar variação de duração.

**T12 — Join videos:** ordenar clipes MP4/MOV/MKV, normalizar codecs/resolução/fps conforme necessário, canvas com tamanho do primeiro, exportar MP4; mostrar aviso sobre letterbox/crop e transcode.

**T13 — Save video frames:** stepping preciso por frame, escolher pontos, exportar PNG em resolução completa; nomes identificáveis por timecode.

**T14 — Split video:** marcar cortes livres ou dividir em N partes iguais; exportar cada segmento para pasta de resultados.

**T15 — Redact video:** selecionar regiões sólidas/desfoque e intervalos de tempo independentes; prévia e renderização real dos pixels afetados em cada frame.

### 5.4 Áudio (5 publicadas em `/tools`)

**T16 — Normalize volume:** controle de loudness/range e true peak, comparação nível original/destino; especificar LUFS/limiter/peak e proteção de clipping no clone.

**T17 — Create an audio visualizer:** MP4 com waveform animada ou imagem estática; formatos paisagem, retrato, quadrado; escolha de fundo/cores/duração/qualidade.

**T18 — Trim audio:** waveform para ajustar início/fim, timecodes exatos, opção para eliminar silêncio **apenas do começo e fim**; prévia.

**T19 — Convert audio channels:** mono/estéreo; ganho independente esquerdo/direito; ouvir cada canal isoladamente; downmix/upmix sem clipping.

**T20 — Bleep audio:** intervalos selecionados com beep, mover ou editar bordas dos trechos, audição comparada entre original e resultado.

### 5.5 PDF (2 publicadas em `/tools`)

**T21 — Merge PDFs:** vários PDFs, ordem inicial baseada na seleção do Finder; usuário pode reordenar antes de salvar documento único.

**T22 — Organize PDF pages:** miniaturas de páginas, reordenar, girar, duplicar e apagar páginas individuais; salvar cópia revisada. `[PROPOSTO]` zoom, multi-seleção, importação entre PDFs e preservação de metadados/outline na medida viável.

### 5.6 Recursos adicionais mencionados fora da lista `/tools`

**T23 — Split PDFs [CONFIRMADO pela App Store; ausente do inventário nominal da página Tools]:** dividir PDF em documentos separados. O site não especifica regras (por páginas, intervalos, tamanho). `[PROPOSTO]` oferecer intervalos, extração selecionada e N páginas por arquivo.

**T24 — Read QR codes [CONFIRMADO pela App Store; ausente do inventário nominal da página Tools]:** interpretar códigos QR. Não há descrição de UI, entrada suportada ou formato de exportação. `[PROPOSTO]` detectar QR em foto/PDF, mostrar texto e permitir copiar/abrir link após confirmação; leitura inteiramente local via Vision.

**T25–T26 — NÃO IDENTIFICADAS PUBLICAMENTE:** o marketing fala de 26 ferramentas, mas as páginas consultadas não permitem afirmar quais são as restantes, ou se o total contabiliza outras ações como ferramenta. **Não inventar recursos como se fossem Tangerine**. Um clone pode oferecer propostas extras claramente próprias, por exemplo watermark e renomeação em lote, apenas se desejadas.

### 5.7 Criar PDF a partir de imagens [CONFIRMADO, apresentado como operação de seleção múltipla]

Selecionar diversas imagens, inclusive formatos diferentes; cada imagem vira uma página do novo PDF. `[PROPOSTO]` controlar ordem, página A4/Letter/tamanho da foto, orientação, margens, fit/contain/fill, resolução e metadados. Não classificar arbitrariamente como ferramenta 25/26.

## 6. Seis ações de arquivo (não são edições de mídia)

| Ação | Comportamento público | Detalhes de implementação propostos |
|---|---|---|
| AirDrop | Abre seletor nativo de destinatário para arquivos/pastas | `NSSharingService` apropriado; tratar tipo não suportado e cancelamento; nunca copiar dados para servidor próprio |
| Float | Coloca arquivos em prateleira flutuante, fixável à borda da tela; permite arrastar para outro app | shelf persistente/opcional, multi-monitor, drag-out com `NSPasteboard`/file promises; sem duplicar arquivo até haver drop válido |
| Copy | Copia arquivos para clipboard, prontos para colar no Finder | preferir objetos de arquivo/URLs no pasteboard, sem apenas texto do caminho |
| Move | Escolher pasta destino e **mover originais** | distinguir de edição que salva cópia; confirmação de destino, conflitos, cross-volume, undo quando possível |
| Copy Path | Copia caminhos completos como texto, um por linha em seleção múltipla | usar paths legíveis de arquivos locais, mostrar opção quote para shell separadamente |
| Terminal | Abre pasta ou a pasta contenedora de arquivo no Terminal ou iTerm2 | preferência de terminal, caminho com espaços seguro; evitar executar comandos arbitrários; respeitar sandbox/Automation |

## 7. Fluxos de usuário ponta a ponta [CONFIRMADOS no comportamento, parâmetros PROPOSTOS]

1. **HEIC → JPG:** selecionar `.heic` → arrastar → Shift → JPG → soltar → indicador de andamento → arquivo vizinho com nome sem colisão → Reveal in Finder.
2. **PNG + HEIC → JPG:** selecionar ambos → Shift → JPG comum a ambos → 2 outputs → 1 lote com progresso individual.
3. **JPG com metadados sensíveis:** arrastar → Command → Edit metadata → apagar localização → gravar nova cópia → validar ausência de GPS.
4. **Screenshot social:** Command → Add a background → escolher gradiente, ratio e padding → exportar cópia.
5. **Vídeo comprido:** Command → Trim video → ajustar timecode/frame → exportar corte sem modificar origem.
6. **Vídeos múltiplos:** selecionar MP4/MOV/MKV → Command → Join videos → ordenar → export MP4.
7. **PDFs múltiplos:** Command → Merge PDFs → reordenar → confirmar → PDF final.
8. **Seleção mista + pasta:** Control → Copy Path / Move / Float → executa livremente, como conversões e ferramentas.
9. **Uso ilimitado:** processar o primeiro, o 20º, o 21º e o 10.000º arquivo sob as mesmas regras, sem contador, licença nem tela de pagamento.
10. **Sem permissão:** usuário escolhe pasta pelo diálogo nativo → autorização local persistida conforme necessidade → processa; nunca apaga original em falha.

## 8. Telas e componentes da aplicação equivalente

Estes são **requisitos de projeto recomendados**, não uma reprodução verificada de todas as telas internas.

### 8.1 Menu bar popover

Status: ativo/pausado, última operação, abrir Settings, histórico local, importação manual, ajuda e sair. Ícone e nome próprios. **Sem botões de compra/restauração.**

### 8.2 Onboarding / Permissões

Boas-vindas; demonstração interativa Shift/Command/Control; verificação e explicação de Accessibility/Input Monitoring caso estritamente necessários; validação de permissões macOS; drag-test; seleção de pasta de teste; privacidade e licença. Permitir continuar em modo limitado sem permissão global.

### 8.3 Radial wheel

Centro com preview/tipo/quantidade; setores com ícone/abreviação; estado disabled explicado; hover com transformação; ação `more` em anel/segunda página; hit test confiável; janela overlay sem ativar app principal ou sequestrar drag; animação 120–180 ms como meta proposta; posicionamento dentro de tela útil; múltiplos monitores; acessibilidade.

### 8.4 Janelas de operações avançadas

Header (nome, tipo, tamanho), preview canvas/player/documento; painel lateral de parâmetros; Reset, Cancel, Export; indicadores de tamanho e dimensões; validação in-line; undo/redo quando possível; saída nova.

### 8.5 Jobs/progresso

Lista compacta de jobs com título, inputs, destino, progresso total e por arquivo, estágio, duração, pausar/cancelar quando permitido, resultado individual, Reveal e Retry; cancelamento não deixa arquivos parcialmente válidos.

### 8.6 Float shelf

Lista/card de ícones e miniaturas, drag-out, remover sem apagar arquivo original, pin/unpin esquerda/direita, monitor, auto-hide, clear; sessão opcional entre launches com bookmarks.

### 8.7 Settings

Geral (abrir ao iniciar sessão do macOS, idioma, aparência, atualizações), Gestos/teclas (atalhos distintos e conflito), Output (origem vs pasta fixa, sufixos, política de colisão), Conversão (qualidade e perfis), Privacidade (limpar histórico e bookmarks), Integrações (iTerm2), Diagnostics (logs locais redigidos), About. **Sem aba License/Trial.**

### 8.8 Uso ilimitado — decisão do produto

**Nenhuma verificação de licença ou quantidade de arquivos** deve ser implementada. Não usar StoreKit, paywall, contador, créditos, desbloqueio ou trial. Todas as conversões, ferramentas e seis ações estarão disponíveis desde o primeiro uso e continuarão após quaisquer quantidades de arquivos, inclusive em lotes. O modelo de monetização do Tangerine é registrado neste relatório apenas para análise concorrencial, **não é parte do clone funcional**.

## 9. Arquitetura técnica recomendada para macOS

### 9.1 Stack

- **Swift + SwiftUI + AppKit** para macOS 13+; AppKit em overlay, drag/drop, `NSPanel`, status bar, eventos e integrações Finder; SwiftUI em formulários e janelas.
- **Async/await, atores e filas** para jobs/cancelamento; UI sempre na main thread; `OSLog` para logs locais sem caminhos privados por padrão.
- **ImageIO / Core Image / Accelerate / Vision** para imagens, ajuste, redaction e QR; **AVFoundation / VideoToolbox / Core Audio** para áudio/vídeo básicos; **PDFKit / Quartz** para operações de PDF.
- **UniformTypeIdentifiers** para identificação por conteúdo/UTType, sem confiar somente na extensão.
- **UserDefaults/JSON/SwiftData** para preferências e histórico mínimo local. **Sem StoreKit/licenciamento nesta versão**.
- **Engines externas complementares** (se justificadas): FFmpeg para contêineres/codecs/efeitos não cobertos; bibliotecas Office/EPUB/archive próprias ou integradas. Verificar licença, assinatura, notarização, tamanho, arquitetura arm64 e política de App Sandbox antes de adotar. **Não presumir que LibreOffice/Pandoc/FFmpeg existam instalados no Mac do usuário**, nem chamar `brew` em produção.

### 9.2 Componentes e contratos

```text
MenuBarApp / Onboarding / Settings
                 │
DragIntentDetector ──> RadialCoordinator ──> ToolAvailabilityRegistry
                 │              │
          FileSelectionResolver  └──> ActionDispatcher / FloatShelf
                 │
          OperationPreflight ──────────────────> JobQueue
                                                   │
                       ConversionEngine / EditorEngine / ActionEngine
                                                   │
                  SandboxFileAccess / OutputWriter / FinderReveal
                                                   │
                                       JobStore / Diagnostics
```

Contratos mínimos:

```swift
struct FileDescriptor: Sendable {
    let url: URL
    let displayName: String
    let contentTypeIdentifier: String
    let sizeBytes: Int64?
    let isDirectory: Bool
}
struct OperationDescriptor: Sendable {
    let id: String
    let supportedInputTypes: Set<String>
    let outputType: String?
    let allowsBatch: Bool
    let allowsDirectories: Bool
    let requiresConfiguration: Bool
}
enum JobStatus: String, Codable { case queued, preflighting, running, completed, failed, cancelled }
protocol FileOperationEngine: Sendable {
    func isSupported(_ files: [FileDescriptor]) async -> Bool
    func execute(_ job: OperationJob, progress: @Sendable (Double) -> Void) async throws -> [URL]
}
```

Os tipos são **esboços contratuais**, não código de produção completo. Decidir isolamento de Swift 6, cancelamento, progress observers e extensões de formatos ao implementá-los.

### 9.3 Permissões e App Sandbox

1. Para leitura e escrita fora do contêiner, usar `NSOpenPanel/NSSavePanel` quando necessário e URLs com escopo de segurança; persistir bookmarks somente com necessidade e revogar no UI.
2. A prova de conceito de drag global deve testar **Finder, Desktop, apps de terceiros e macOS 13–atual**, com overlay e e sem sandbox; documentar limites honestamente.
3. Monitores globais de teclado podem exigir acessibilidade/trust do usuário; explicar exatamente a permissão e respeitar negativa; **não** contornar proteções do macOS.
4. Drag de aplicativos pode transportar `NSFilePromiseProvider`, não URL materializada; tratar com API nativa e cancelamento, sem assumir que clipboard normal expõe o drag.
5. Testar publicação no Mac App Store com `com.apple.security.app-sandbox` e entitlements mínimos, sem prometer aprovação antes de verificar.

### 9.4 Pipeline de escrita seguro

`read input -> capability/preflight -> authorized destination -> transform into temp on same volume where possible -> validate signature/output -> atomic move to unique final name -> success event -> cleanup temp`. Nunca sobrescrever o arquivo de origem nas conversões/edições. `Move` é a exceção explícita com intenção do usuário. Em cancelamento, remover apenas temporários que pertencem ao job.

### 9.5 Tratamento de falhas obrigatório

- arquivo sem acesso, pasta protegida, bookmark obsoleto, disco cheio, nome em conflito, arquivo bloqueado, symlink, pacote `.app`, iCloud não baixado, volume externo desconectado;
- formatos corrompidos, DRM, PDF cifrado, senha inválida, codec ausente, texto não reconhecido e perda de fidelidade;
- seleção mista sem destino comum, arquivos vazios, lote parcial, cancelamento, force quit, sleep/wake;
- multi-monitor Retina, arrasto entre Spaces, fullscreen, Dock/Stage Manager, Finder relançado, teclado internacional e teclas remapeadas;
- redaction incompleto, metadados não removidos, archives com `../` ou caminhos absolutos, entradas gigantes/zip bombs.

## 10. Plano de implantação realista por fases

**Fase 0 — POC de risco (bloqueante):** app status bar, captura de intenção de drag de arquivo de Finder/Área de Trabalho, overlay radial, drop com URL de arquivo, sandbox e permissões. Demonstrar funcionando num Mac real sem depender de API privada. Se falhar em determinados contextos, entregar alternativa explícita e evidência da limitação.

**Fase 1 — Núcleo utilizável:** imagem JPG/PNG/HEIC/WebP/TIFF, conversão em lote, detecção UTType, menu, saída segura, jobs, 6 ações de arquivo (onde OS permitir), settings, testes.

**Fase 2 — Ferramentas de imagem:** compress, crop, edição, anotações, fundo, collage, redaction local e metadados.

**Fase 3 — Vídeo e áudio:** suporte avançado de containers, trim/split/join/speed, crop, frames, volume, channels, visualizer, bleep, redaction temporal.

**Fase 4 — PDF/Office/archives/legendas:** merge/organize/split/assemble, extração/renderização, exportações genuínas de Office, EPUB e compactados com matriz real.

**Fase 5 — Polimento e distribuição:** onboarding, acessibilidade, performance, E2E, crash recovery, signing/notarization e distribuição. Sem paywall, trial ou cota.

Não iniciar centenas de formatos simultaneamente antes de validar a interação macOS e as restrições de sandbox.

## 11. Critérios de aceite e testes

| ID | Cenário | Critério verificável |
|---|---|---|
| A01 | Drag Finder + Shift | roda abre corretamente durante drag real e não bloqueia Finder |
| A02 | Troca Shift→Command→Control | estado muda sem perder seleção; cancelamento não executa operação |
| A03 | HEIC → JPEG | foto válida e visível, original intacto, cor/orientação coerentes |
| A04 | Lote PNG+HEIC → JPG | 2 resultados; falha de um não corrompe o outro |
| A05 | Nomes iguais | gera sufixo determinístico sem sobrescrita |
| A06 | Sem permissão | diálogo explicativo e alternativa de escolha de pasta |
| A07 | Redact imagem | área coberta nos pixels finais e metadata limpos quando selecionado |
| A08 | Split/join vídeo | número/ordem/duração de segmentos previstos dentro de tolerância |
| A09 | PDF merge/reorder | páginas renderizam na ordem escolhida |
| A10 | QR local | texto detectado sem rede; links não executados automaticamente |
| A11 | Archive malicioso | impede path traversal e bombs por limite configurado |
| A12 | Offline | conversões suportadas e ações funcionam sem Internet |
| A13 | Mais de 20 arquivos | o 21º e seguintes são processados normalmente, sem tela de desbloqueio |
| A14 | Uso offline ilimitado | 100+ arquivos sem Internet, sem login, contador ou licença |
| A15 | Cancelamento | limpa temporários, preserva originais e revela erro por arquivo |
| A16 | App Store / sandbox | teste em release assinado com permissões reais e engine empacotada |
| A17 | Accessibility negado | não faz monitoramento indevido; modo manual utilizável |
| A18 | Desempenho | UI responsiva durante jobs e limitação de concorrência e memória |

**Fixtures essenciais:** JPG com EXIF/GPS/ICC/alpha, HEIC rotacionado, WebP animado, PNG transparente, PDF multipágina/criptografado/escaneado, DOCX com tabelas/imagens, PPTX com fontes, XLSX com fórmulas/abas, VFR MOV 4K, MP4 sem som, MKV multi-trilha, WAV mono/estéreo, MP3 VBR, FLAC, SRT/VTT, ZIP/TAR/GZIP/RAR, arquivos de 0 bytes, nomes Unicode/acentos, arquivos grandes e symlink.

## 12. Design e diferenciação legal

Replicar o **conceito de fluxo** (drag + menu contextual + processamento local) e capacidades comuns. Criar nome comercial, ícone, copy, cores, componentes e animações próprios. Não baixar e redistribuir assets do press kit como interface final nem afirmar afiliação com Leap Studio. A documentação pública **não concede licença** sobre código ou visual do app. Recomendações adicionais de produto: presets salvos, histórico local opcional, filas robustas, modo menu/atalho de acessibilidade e diagnóstico transparente de compatibilidade de formatos.

## 13. Questões em aberto que exigem teste do app original

1. Nomes e semântica das **duas ferramentas não individualizadas** no site/App Store.
2. Relação exata das **275 rotas**, incluindo 1→N páginas e formatos animados.
3. Comportamento exato de atalhos customizados, overlay em Full Screen e Finder com teclado diferente.
4. Se a App Store 2.0.1 implementa PDF→EPUB apesar de avaliação anterior apontar ausência.
5. Qualidade de PDF→DOCX/PPTX/XLSX/Pages/EPUB e dependências reais.
6. No produto a desenvolver, testar desempenho, cancelamentos e confiabilidade com lotes extensos; não reproduzir o trial do concorrente.
7. Tratamento de iCloud placeholders, security scope e file promises.
8. Campos detalhados, presets e parâmetros de todas as janelas avançadas.

## 14. Fontes públicas e técnicas

### Fontes sobre Tangerine

- **F1** Home/Features: https://www.tangerineformac.com/
- **F2** Press kit e descrição de funcionamento: https://www.tangerineformac.com/press
- **F3** Privacy Policy, 17/09/2026: https://www.tangerineformac.com/privacy
- **F4** App Store (versão 2.0.1 consultada em 22/10/2026): https://apps.apple.com/us/app/tangerine-file-converter/id6813034065
- **F5** Publicação pública do desenvolvedor, com preço/trial/menu Actions: https://www.reddit.com/r/macapps/comments/1xalehy/tangerine_convert_files_with_just_drag_shift/
- **F6** Página de ferramentas e detalhes: https://www.tangerineformac.com/tools
- **F7** Screenshot de menu de conversão: https://www.tangerineformac.com/press/screenshots/conversion-wheel.png
- **F8** Screenshot de ferramentas: https://www.tangerineformac.com/press/screenshots/advanced-tools.png
- **F9** Screenshot editor de imagem: https://www.tangerineformac.com/press/screenshots/edit-photo.png
- **F10** Screenshot background: https://www.tangerineformac.com/press/screenshots/add-background.png
- **F11** Screenshot áudio: https://www.tangerineformac.com/press/screenshots/audio-tools.png

### Referências primárias de APIs Apple para implementação

- **A1** Event monitor global: https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)
- **A2** App Sandbox e security-scoped bookmarks: https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox
- **A3** Drag & drop e file promises: https://developer.apple.com/documentation/appkit/supporting-drag-and-drop-through-file-promises

---

**Importante:** esta é uma reconstrução de **requisitos públicos e arquitetura sugerida**, não uma engenharia reversa do binário. O documento irmão `PROMPT_MASTER_Claude_Code_Conversor_Mac.md` converte esta análise em instruções operacionais de implementação para o Claude Code.
