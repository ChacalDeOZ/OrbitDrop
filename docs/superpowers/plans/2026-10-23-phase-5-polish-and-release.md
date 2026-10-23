# Phase 5 Polish, Onboarding, Accessibility and Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Concluir a Fase 5 de polimento final do OrbitDrop: construir janela de Onboarding em 5 passos com tutorial interativo, implementar navegação completa por teclado e VoiceOver/Reduce Motion, configurar entitlements de Hardened Runtime/App Sandbox, documentar checklist de distribuição e executar auditoria de conformidade 100% offline e ilimitada.

**Architecture:** Componentes em `Sources/OrbitDropKit/Onboarding/`, `Sources/OrbitDropKit/Accessibility/` e `Distribution/`. Janela nativa AppKit para o fluxo de 5 passos, navegação desacoplada para teclas direcionais no menu radial e testes de auditoria de conformidade.

**Tech Stack:** Swift 6.4, macOS 13+, AppKit, CoreGraphics, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-23-phase-5-polish-and-release-design.md`

## Global Constraints
- 100% offline: sem entitlements de rede (`com.apple.security.network.client` ausente).
- Zero trial / ilimitado: ausência absoluta de StoreKit, licenças, assinaturas ou cotas de uso.
- Onboarding em 5 passos exatos: Boas-vindas, Demonstração interativa, Permissões, Primeiro teste e Conclusão.
- Acessibilidade: suporte a VoiceOver e Reduce Motion.

## Review Focus
- Onboarding após primeiro uso -> não reaparece automaticamente no próximo launch (persiste flag).
- Tecla Escape no menu radial -> cancela sem executar ou travar.
- Setas do teclado com contagem de setores 1 ou 0 -> wrap-around seguro sem out-of-bounds.
- Entitlements sem rede -> compilação release assinada com sucesso.

---

### Task 1: Onboarding em 5 Passos (`OnboardingWindowController`)

**Files:**
- Create: `Sources/OrbitDropKit/Onboarding/OnboardingStep.swift`
- Create: `Sources/OrbitDropKit/Onboarding/OnboardingState.swift`
- Create: `Sources/OrbitDropKit/Onboarding/OnboardingWindowController.swift`
- Test: `Tests/OrbitDropKitTests/OnboardingTests.swift`

**Interfaces:**
- Consumes: `AccessibilityChecker`, `UserDefaults`
- Produces: `OnboardingState.hasCompletedOnboarding`, `OnboardingWindowController.show()`

- [ ] **Step 1: Escrever teste de Onboarding**
Criar `Tests/OrbitDropKitTests/OnboardingTests.swift` testando:
1. Sequência e transição entre os 5 passos (`welcome`, `interactiveDemo`, `permissions`, `firstTest`, `completed`).
2. Persistência de conclusão em `UserDefaults`.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter OnboardingTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `OnboardingStep`, `OnboardingState` e `OnboardingWindowController`**
Janela nativa com barra de progresso dos 5 passos e botões de avanço.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter OnboardingTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Onboarding/ Tests/OrbitDropKitTests/OnboardingTests.swift
git commit -m "feat(onboarding): implement 5-step native onboarding flow"
```

---

### Task 2: Acessibilidade e Navegação por Teclado (`KeyboardNavigator`)

**Files:**
- Create: `Sources/OrbitDropKit/Accessibility/KeyboardNavigator.swift`
- Create: `Sources/OrbitDropKit/Accessibility/AccessibilityManager.swift`
- Test: `Tests/OrbitDropKitTests/AccessibilityTests.swift`

**Interfaces:**
- Consumes: `RadialItem`, `NSWorkspace`
- Produces: `KeyboardNavigator.nextIndex(...)`, `KeyboardNavigator.previousIndex(...)`, `AccessibilityManager.shouldReduceMotion`

- [ ] **Step 1: Escrever teste de navegação por teclado e acessibilidade**
Criar `Tests/OrbitDropKitTests/AccessibilityTests.swift` testando:
1. Avanço e retrocesso circular de setores (wrap-around 0 -> N-1 e N-1 -> 0).
2. Verificação de flags de acessibilidade do sistema sem exceção.

- [ ] **Step 2: Rodar teste para verificar falha**
Run: `swift test --filter AccessibilityTests`
Expected: FAIL.

- [ ] **Step 3: Implementar `KeyboardNavigator` e `AccessibilityManager`**
Lógica pura de navegação e helper de acessibilidade AppKit.

- [ ] **Step 4: Rodar teste para verificar sucesso**
Run: `swift test --filter AccessibilityTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Sources/OrbitDropKit/Accessibility/ Tests/OrbitDropKitTests/AccessibilityTests.swift
git commit -m "feat(a11y): implement KeyboardNavigator and AccessibilityManager"
```

---

### Task 3: Entitlements de Distribuição e Documentação de Release

**Files:**
- Create: `Distribution/OrbitDrop.entitlements`
- Create: `Documentation/DISTRIBUTION.md`
- Create: `Documentation/PRIVACY.md`
- Modify: `Scripts/build_app.sh`

- [ ] **Step 1: Criar `Distribution/OrbitDrop.entitlements`**
Entitlements de segurança sem permissão de rede (`com.apple.security.network.client` ausente).

- [ ] **Step 2: Criar `Documentation/DISTRIBUTION.md` e `Documentation/PRIVACY.md`**
Checklist de notarização Apple, assinatura ad-hoc e política de privacidade 100% offline.

- [ ] **Step 3: Atualizar `Scripts/build_app.sh`**
Integrar entitlements ao comando `codesign --entitlements Distribution/OrbitDrop.entitlements`.

- [ ] **Step 4: Executar build script e verificar assinatura**
Run: `./Scripts/build_app.sh`
Expected: Bundle assinado com entitlements aplicados.

- [ ] **Step 5: Commit**
```bash
git add Distribution/ Documentation/DISTRIBUTION.md Documentation/PRIVACY.md Scripts/build_app.sh
git commit -m "chore(release): configure security entitlements and distribution checklist"
```

---

### Task 4: Auditoria Final de Conformidade Ilimitada e Offline

**Files:**
- Create: `Tests/OrbitDropKitTests/ComplianceAuditTests.swift`

- [ ] **Step 1: Escrever teste de auditoria de conformidade**
Criar `Tests/OrbitDropKitTests/ComplianceAuditTests.swift` testando:
1. Ausência de StoreKit em tempo de execução.
2. Comprovação de que todas as 24 ferramentas públicas estão mapeadas.
3. Ausência de contadores limitadores em `UserDefaults`.

- [ ] **Step 2: Rodar teste para verificar sucesso**
Run: `swift test --filter ComplianceAuditTests`
Expected: PASS.

- [ ] **Step 3: Commit**
```bash
git add Tests/OrbitDropKitTests/ComplianceAuditTests.swift
git commit -m "test(compliance): assert zero-storekit, zero-trial and 24 tools mapping"
```

---

### Task 5: Integração no `AppDelegate`, Recompilação Final e Validação

**Files:**
- Modify: `Sources/OrbitDropApp/AppDelegate.swift`
- Modify: `Sources/OrbitDropKit/UI/RadialWheelView.swift`
- Modify: `FEATURE_MATRIX.md`
- Modify: `TASKS.md`
- Modify: `README.md`

- [ ] **Step 1: Conectar navegação de teclado na `RadialWheelView` e Onboarding no `AppDelegate`**
1. Se primeiro launch, abrir `OnboardingWindowController`.
2. Habilitar navegação por setas e Enter/Space no menu radial.
3. Adicionar item "Boas-Vindas / Tutorial..." no menu da barra de status.

- [ ] **Step 2: Executar suite completa de testes**
Run: `swift test`
Expected: PASS com 100% dos testes.

- [ ] **Step 3: Recompilar e empacotar bundle release final**
Run: `./Scripts/build_app.sh`
Expected: `build/OrbitDrop.app` gerado e assinado com sucesso.

- [ ] **Step 4: Atualizar documentações finais**
Registrar conclusão integral do projeto em `FEATURE_MATRIX.md`, `TASKS.md` e `README.md`.

- [ ] **Step 5: Commit final da Fase 5 e push no GitHub**
```bash
git add Sources/ FEATURE_MATRIX.md TASKS.md README.md
git commit -m "feat(phase-5): complete onboarding, accessibility, release polish and compliance audit"
git push origin main
```
