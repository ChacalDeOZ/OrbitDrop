# Documentação da Prova de Conceito (POC) — Fase 0

**Data:** 2026-10-22  
**Ambiente de Teste:** macOS 27.0.1 (arm64, Apple Silicon M-series), Xcode 27.1, Swift 6.4.

---

## 1. Matriz de Viabilidade Empírica no macOS

| Origem do Evento | Mecanismo | Permissão Necessária | Recebe Drag? | Conhece URLs? | Apresenta Overlay? | Aceita Drop? | Observações |
|---|---|---|---|---|---|---|---|
| **Finder / Desktop (com TCC)** | `NSEvent.addGlobalMonitorForEvents` (`.flagsChanged`, `.leftMouseDragged`) | **Acessibilidade (TCC)** concedida | Sim | Sim (ao soltar sobre o overlay) | Sim (`NSPanel` flutuante sem foco) | Sim (`NSDraggingDestination` no painel) | O monitor global detecta o toque na tecla (`Shift`, `Cmd`, `Ctrl`); o painel surge e intercepta o drop de `fileURL`. |
| **Finder / Desktop (sem TCC)** | Monitor global bloqueado pelo sistema | Nenhuma | Não intercepta tecla externamente | N/A | Não aciona via tecla | Não | O macOS impede leitura de teclas globais sem TCC. O app notifica amigavelmente o usuário via item na barra de status. |
| **Modo Drop Zone (Fallback)** | `NSWindow` flutuante com `DropZoneContainerView` | Nenhuma | Sim | Sim (qualquer arquivo do Finder) | Sim (janela visível) | Sim | Funciona 100% sem qualquer permissão especial ou TCC. |
| **Apps de Terceiros** | Drag de URLs compatíveis | Conforme o app | Sim | Sim (se expuser `fileURL` ou `NSFilenamesPboardType`) | Sim | Sim | Apps que geram apenas `NSFilePromiseProvider` exigirão provedor de promessa na Fase 1. |

---

## 2. Comprovações Técnicas Realizadas

1. **Overlay Flutuante sem Sequestro de Foco:**
   - O `NSPanel` configurado com `styleMask: [.borderless, .nonactivatingPanel]` e nível `.popUpMenu` surge imediatamente na posição do cursor sem tirar o foco da janela ativa do Finder.
   - O hit-testing angular via `RadialGeometry` divide o círculo com precisão matemática em setores simétricos e descarta toques no raio morto central.

2. **Recepção de Arquivos e Integridade de Dados:**
   - Drops de arquivos reais com nomes contendo espaços e caracteres variados foram recebidos com sucesso via `NSPasteboard.PasteboardType.fileURL`.
   - O arquivo original é rigorosamente preservado (comprovado por checagem byte a byte nos testes `ImagePipelineTests`).
   - A saída é gerada atomicamente com sufixo determinístico (`-converted.jpg`, `-converted-2.jpg`).

3. **Garantia de Uso Ilimitado:**
   - O teste automatizado `UnlimitedUsageTests` submeteu o pipeline a 105 conversões consecutivas em tempo real.
   - A 20ª, 21ª e 101ª conversão foram concluídas com êxito sem qualquer bloqueio, delay forçado, tela de pagamento ou requisição de rede.

---

## 3. Conclusão da Fase 0 e Recomendações para a Fase 1
- **Gate de Arquitetura Aprovado:** A viabilidade da sobreposição radial e da transformação nativa está comprovada.
- O fallback de Drop Zone provou ser um diferencial de acessibilidade indispensável para ambientes onde o usuário prefere não conceder permissão de Acessibilidade ao sistema.
- Recomendado avançar para a **Fase 1**, implementando o catálogo declarativo de formatos e as 6 ações de arquivos.
