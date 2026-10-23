# OrbitDrop — Guia de Distribuição e Assinatura no macOS

Este documento detalha o checklist de release para distribuição do OrbitDrop fora da App Store (Direct Distribution notarizada pela Apple) e na Mac App Store.

---

## 1. Princípios de Segurança e Privacidade
- **Zero Network Entitlements:** O arquivo `Distribution/OrbitDrop.entitlements` não contém permissões de conexão à rede (`com.apple.security.network.client` ausente).
- **Hardened Runtime:** Exigido pela Apple para notarização desde o macOS 10.14.5.
- **Arm64 Nativo:** O binário é compilado exclusivamente para arquitetura Apple Silicon (M1 ou superior).

---

## 2. Checklist de Compilação e Notarização

### 2.1 Compilação do Bundle Release
Execute o script automatizado:
```bash
./Scripts/build_app.sh
```
O aplicativo assinado ad-hoc é gerado em `build/OrbitDrop.app`.

### 2.2 Assinatura com Certificado Apple Developer (ID de Desenvolvedor)
Para distribuir a usuários finais:
```bash
# 1. Identificar certificado
security find-identity -p codesigning -v

# 2. Assinar binário e bundle com Hardened Runtime e Entitlements
codesign --deep --force --options runtime \
         --entitlements Distribution/OrbitDrop.entitlements \
         --sign "Developer ID Application: SEU_NOME (TEAM_ID)" \
         build/OrbitDrop.app

# 3. Validar assinatura
codesign --verify --deep --strict --verbose=2 build/OrbitDrop.app
spctl --assess --type execute --verbose build/OrbitDrop.app
```

### 2.3 Notarização com Notarytool
```bash
# 1. Criar arquivo ZIP ou DMG para envio
ditto -c -k --keepParent build/OrbitDrop.app build/OrbitDrop.zip

# 2. Submeter à Apple
xcrun notarytool submit build/OrbitDrop.zip \
      --keychain-profile "AC_PASSWORD" \
      --wait

# 3. Anexar ticket de notarização (Stapling)
xcrun stapler staple build/OrbitDrop.app
```

### 2.4 Criação de Imagem DMG para Usuários Finais
```bash
hdiutil create -volname "OrbitDrop" -srcfolder build/OrbitDrop.app -ov -format UDZO build/OrbitDrop-Installer.dmg
```

---

## 3. Modelo de Licença e Uso Ilimitado
O OrbitDrop não implementa verificação de licença, StoreKit, trials ou limitações de arquivo. Qualquer pessoa pode executar conversões, edições e lotes de arquivos ilimitadamente de forma 100% gratuita e local.
