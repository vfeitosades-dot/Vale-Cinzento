#!/usr/bin/env bash
set -euo pipefail
umask 077
out="$RUNNER_TEMP/pacotes"
mkdir -p "$out"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$RUNNER_TEMP/vale-release.jks"
if [[ -n "${ANDROID_SIGNING_STORE:-}" ]]; then
  printf '%s' "$ANDROID_SIGNING_STORE" | base64 --decode > "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${ANDROID_SIGNING_ALIAS:?Missing alias}"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="${ANDROID_SIGNING_PASSWORD:?Missing password}"
else
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER=travessia
  GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(openssl rand -hex 32)"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
  echo "::add-mask::$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"
  keytool -genkeypair -storetype PKCS12 -keyalg RSA -keysize 3072 -validity 10000 \
    -alias "$GODOT_ANDROID_KEYSTORE_RELEASE_USER" -keystore "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
    -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -keypass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD \
    -dname "CN=Vale Cinzento Previa"
fi
godot --headless --editor --import 2>&1 | tee "$RUNNER_TEMP/import.log"
! grep -E 'SCRIPT ERROR|Parse Error|Failed to load script' "$RUNNER_TEMP/import.log" || exit 1
timeout 100s godot --headless -- --verificar-travessia 2>&1 | tee "$RUNNER_TEMP/game.log"
grep -q TRAVESSIA_OK "$RUNNER_TEMP/game.log"
! grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$RUNNER_TEMP/game.log" || exit 1
godot --headless --export-release Windows "$out/Vale-Cinzento-Windows-x64.exe"
godot --headless --export-release Android "$out/Vale-Cinzento-Android-arm64.apk"
sdk="$ANDROID_HOME/build-tools/34.0.0"
"$sdk/apksigner" verify --verbose --print-certs "$out/Vale-Cinzento-Android-arm64.apk"
"$sdk/aapt" dump badging "$out/Vale-Cinzento-Android-arm64.apk" > "$RUNNER_TEMP/apk.txt"
grep -F "package: name='org.valecinzento.travessia'" "$RUNNER_TEMP/apk.txt"
grep -F "native-code: 'arm64-v8a'" "$RUNNER_TEMP/apk.txt"
grep -F 'launchable-activity:' "$RUNNER_TEMP/apk.txt"
if grep -Fq 'android.permission.INTERNET' "$RUNNER_TEMP/apk.txt"; then echo 'Permissão de rede inesperada'; exit 1; fi
file "$out/Vale-Cinzento-Windows-x64.exe" | grep -F 'PE32+'
mkdir -p dist
cp "$out/Vale-Cinzento-Windows-x64.exe" "$out/Vale-Cinzento-Android-arm64.apk" dist/
(cd dist && sha256sum *.exe *.apk > SHA256SUMS.txt)
