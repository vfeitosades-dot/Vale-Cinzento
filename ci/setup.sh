#!/usr/bin/env bash
set -euo pipefail
version=4.4.1
tag="$version-stable"
prefix="Godot_v$tag"
base="https://github.com/godotengine/godot-builds/releases/download/$tag"
cd "$RUNNER_TEMP"
for asset in "${prefix}_linux.x86_64.zip" "${prefix}_export_templates.tpz" SHA512-SUMS.txt; do
  curl --retry 4 -fsSLo "$asset" "$base/$asset"
done
for asset in "${prefix}_linux.x86_64.zip" "${prefix}_export_templates.tpz"; do
  grep -F "$asset" SHA512-SUMS.txt | sha512sum -c -
done
unzip -q "${prefix}_linux.x86_64.zip"
install "${prefix}_linux.x86_64" /usr/local/bin/godot
templates="$HOME/.local/share/godot/export_templates/$version.stable"
mkdir -p "$templates" "$HOME/.config/godot"
unzip -jq "${prefix}_export_templates.tpz" 'templates/windows_release_x86_64.exe' 'templates/windows_debug_x86_64.exe' 'templates/android_release.apk' 'templates/android_debug.apk' 'templates/version.txt' -d "$templates"
cat > "$HOME/.config/godot/editor_settings-4.4.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
SETTINGS
sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
godot --version
