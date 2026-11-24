# Guía para subir Teki a TestFlight

## Requisitos previos

- Xcode instalado con una cuenta de Apple Developer activa
- Flutter SDK configurado
- Certificados de distribución y provisioning profiles configurados en Xcode
- App creada en [App Store Connect](https://appstoreconnect.apple.com) con Bundle ID `pe.teki.app`

---

## Paso 1: Incrementar la versión

Editar `pubspec.yaml` y aumentar el build number (o la versión si corresponde):

```yaml
# Ejemplo: de 1.0.8+10 a 1.0.8+11
version: 1.0.8+11
```

> **Importante:** Cada upload a App Store Connect requiere un build number único. Siempre incrementa el número después del `+`.

---

## Paso 2: Limpiar e instalar dependencias

```bash
flutter clean
flutter pub get
```

---

## Paso 3: Compilar el IPA

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

El IPA se genera en `build/ios/ipa/Teki.ipa` y el archive en `build/ios/archive/Runner.xcarchive`.

---

## Paso 4: Fix de MinimumOSVersion (bug de Flutter 3.35)

Flutter 3.35 no inyecta `MinimumOSVersion` en los frameworks. Hay que agregarlo manualmente y re-exportar:

```bash
# Inyectar MinimumOSVersion
for fw in build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/Info.plist build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/Flutter.framework/Info.plist; do
  /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 13.0" "$fw" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 13.0" "$fw"
done

# Re-exportar el IPA
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa
```

> **Nota:** Si en el futuro actualizas Flutter y este bug se corrige, puedes omitir este paso.

---

## Paso 5: Abrir en Xcode y subir

```bash
open build/ios/archive/Runner.xcarchive
```

Esto abre el **Xcode Organizer**. Luego:

1. Selecciona el archive de **Teki**
2. Click en **"Distribute App"**
3. Selecciona **"App Store Connect"**
4. Click en **"Upload"**
5. Deja las opciones por defecto y click en **"Next"**
6. Selecciona el certificado de distribución y provisioning profile
7. Click en **"Upload"**
8. Espera a que termine la validación y subida

---

## Paso 6: Configurar en App Store Connect

1. Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Ve a **"Apps"** > **Teki** > **TestFlight**
3. Espera a que Apple procese el build (5-15 minutos, recibirás un email)
4. Cuando aparezca el build, te pedirá **Export Compliance**:
   - Selecciona **"Ninguno de los algoritmos mencionados anteriormente"** (la app solo usa HTTPS/TLS del sistema)
5. El build cambiará a estado **"Ready to Test"**

---

## Paso 7: Agregar testers

### Testers internos (hasta 100, aprobación inmediata):
1. En TestFlight > **Internal Testing** > click en **"+"** para crear un grupo
2. Nombra el grupo (ej: "Equipo Teki")
3. Agrega testers por email (deben tener cuenta en App Store Connect)
4. Asigna el build al grupo
5. Los testers reciben un email de invitación

### Testers externos (hasta 10,000, requiere revisión de Apple):
1. En TestFlight > **External Testing** > click en **"+"** para crear un grupo
2. Agrega testers por email
3. Asigna el build y envía a revisión de Apple (tarda 24-48h la primera vez)

---

## Paso 8: Instalar en iPhone

1. El tester recibe un **email de invitación** de Apple
2. Abre el email desde el iPhone
3. Se abre TestFlight automáticamente
4. Click en **"Accept"** > **"Install"**
5. La app se instala en el dispositivo

> Si TestFlight muestra el botón **"Redeem"** en vez de la app, significa que no hay un build activo asignado o la invitación expiró. Reenvía la invitación desde App Store Connect.

---

## Comando rápido: Todo en uno

```bash
# 1. Limpiar y compilar
flutter clean && flutter pub get
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# 2. Fix MinimumOSVersion
for fw in build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/Info.plist build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/Flutter.framework/Info.plist; do
  /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 13.0" "$fw" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 13.0" "$fw"
done

# 3. Re-exportar IPA
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa

# 4. Abrir en Xcode para subir
open build/ios/archive/Runner.xcarchive
```

---

## Solución de problemas

| Error | Solución |
|-------|----------|
| `Invalid MinimumOSVersion` | Ejecutar el fix del Paso 4 |
| `Missing Compliance` | Responder las preguntas de Export Compliance en App Store Connect |
| `Build number already exists` | Incrementar el número después del `+` en `pubspec.yaml` |
| `No signing certificate` | Verificar certificados en Xcode > Settings > Accounts |
| `TestFlight dice "Redeem"` | Reenviar invitación desde App Store Connect |
| `Beta not accepting testers` | No hay build activo, subir un build nuevo y asignarlo al grupo |
