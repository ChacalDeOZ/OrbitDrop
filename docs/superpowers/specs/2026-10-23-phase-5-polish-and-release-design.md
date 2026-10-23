# Especificação Técnica — OrbitDrop: Fase 5 (Polimento Final, Acessibilidade e Distribuição)

**Data:** 2026-10-23  
**Status:** Aprovado para Planejamento  
**Objetivo:** Implementar o fluxo de boas-vindas Onboarding nativo em 5 passos, navegação completa por teclado e conformidade com VoiceOver e Reduce Motion, entitlements de App Sandbox e Hardened Runtime, documentação de distribuição e auditoria final de conformidade 100% offline e ilimitada.

---

## 1. Visão Geral e Requisitos

### 1.1 Fluxo de Onboarding Nativo (5 Passos)
1. **Passo 1 — Boas-Vindas:** Apresentação da marca OrbitDrop, proposta de conversão privada, local, 100% offline e ilimitada.
2. **Passo 2 — Demonstração Interativa:** Canvas interativo simulando gestos com as teclas `Shift` (Conversão), `Command` (Ferramentas) e `Control` (Ações de Arquivo).
3. **Passo 3 — Permissões de Sistema:** Verificação de Acessibilidade (TCC) com status em tempo real e botão nativo para abrir os Ajustes do Sistema.
4. **Passo 4 — Primeiro Teste Real:** Orientação para arrasto de arquivo real de teste ou apresentação da Drop Zone flutuante de fallback.
5. **Passo 5 — Conclusão e Preferências:** Ajustes de inicialização, revelação no Finder e exibição do ícone permanente na barra de menus. O onboarding grava `hasCompletedOnboarding = true` em `UserDefaults` para não reaparecer no próximo launch, com opção de reabrir pelo menu.

### 1.2 Acessibilidade e Teclado
- Suporte total a VoiceOver nos setores da roda radial (`NSAccessibilityButton` com `accessibilityLabel` e `accessibilityHelp`).
- Navegação pelo teclado no menu radial quando aberto:
  - Seta Direita / Baixo: avança para o próximo setor.
  - Seta Esquerda / Cima: retrocede para o setor anterior.
  - Enter / Barra de Espaço: seleciona e executa o setor ativo.
  - Escape: fecha o menu radial sem executar nenhuma ação.
- Conformidade com `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` para desativar transições em usuários sensíveis a movimento.

### 1.3 Entitlements e Distribuição
- `OrbitDrop.entitlements`:
  - `com.apple.security.files.user-selected.read-write`: true.
  - `com.apple.security.files.bookmarks.app-scope`: true.
  - Ausência de `com.apple.security.network.client` e `network.server` (prova técnica irrefutável de operação 100% offline).
- Documentação `DISTRIBUTION.md`:
  - Instruções de compilação release, assinatura hardened runtime, notarização com Apple ID (`xcrun notarytool`) e criação de instalador `.dmg`.

### 1.4 Auditoria Final de Conformidade
- Teste automatizado que varre símbolos em runtime e preferências confirmando:
  - Zero dependências de StoreKit ou serviços de compra.
  - Zero contadores de bloqueio comercial ou telemetria.
  - Operação completa do 1º ao 101º arquivo sem qualquer restrição de uso.

---

## 2. Arquitetura dos Módulos

```text
Sources/OrbitDropKit/
├── Onboarding/
│   ├── OnboardingStep.swift
│   ├── OnboardingState.swift
│   └── OnboardingWindowController.swift
├── Accessibility/
│   ├── AccessibilityManager.swift
│   └── KeyboardNavigator.swift
└── Distribution/
    └── OrbitDrop.entitlements
Documentation/
└── DISTRIBUTION.md
```

---

## 3. Testes Automatizados e Critérios de Aceite
1. **`OnboardingTests`**: validação de sequência dos 5 passos e persistência de conclusão.
2. **`KeyboardNavigatorTests`**: ciclo de seleção de setores via teclado (avançar, retroceder, wrap-around).
3. **`ComplianceAuditTests`**: auditoria de código assegurando ausência total de paywall, licença e rede.
