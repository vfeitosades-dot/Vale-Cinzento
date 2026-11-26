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
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/android-sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
mkdir -p "$ANDROID_HOME"
if ! command -v sdkmanager >/dev/null 2>&1; then
  sdkmanager_path="$(find "$ANDROID_HOME/cmdline-tools" -type f -name sdkmanager 2>/dev/null | head -n 1 || true)"
  if [[ -z "$sdkmanager_path" ]]; then
    curl --retry 4 -fsSLo "$RUNNER_TEMP/android-commandline.zip" https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    mkdir -p "$RUNNER_TEMP/android-commandline" "$ANDROID_HOME/cmdline-tools"
    unzip -q "$RUNNER_TEMP/android-commandline.zip" -d "$RUNNER_TEMP/android-commandline"
    mv "$RUNNER_TEMP/android-commandline/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    sdkmanager_path="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  fi
  export PATH="$(dirname "$sdkmanager_path"):$PATH"
  echo "$(dirname "$sdkmanager_path")" >> "$GITHUB_PATH"
fi
printf 'ANDROID_HOME=%s\nANDROID_SDK_ROOT=%s\n' "$ANDROID_HOME" "$ANDROID_SDK_ROOT" >> "$GITHUB_ENV"
cat > "$HOME/.config/godot/editor_settings-4.4.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
SETTINGS
(set +o pipefail; yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null)
sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
godot --version
