#!/usr/bin/env bash
# This script runs on the disposable Linux host allocated to GitHub Actions.
set -euo pipefail
apk="$1"
pkg=org.valecinzento.travessia
logs="$GITHUB_WORKSPACE/evidencias"
mkdir -p "$logs"
sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
avdmanager="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
test -r /dev/kvm || { echo 'O runner precisa oferecer um dispositivo KVM.' >&2; exit 1; }
sudo chmod a+rw /dev/kvm
"$sdkmanager" "emulator" "platform-tools" "system-images;android-30;google_apis;x86_64" >/dev/null
echo no | "$avdmanager" create avd --force -n vale_ci -k "system-images;android-30;google_apis;x86_64" --device pixel_2 >/dev/null
emulator -avd vale_ci -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -feature -Vulkan -cores 2 -memory 2304 -skin 720x1280 > "$logs/emulador.log" 2>&1 &
emulator_pid=$!
cleanup() {
  adb logcat -d -s godot:V Godot:V AndroidRuntime:E libc:F > "$logs/jogo.log" 2>/dev/null || true
  adb emu kill >/dev/null 2>&1 || true
  kill "$emulator_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT
timeout 150 adb wait-for-device
for tick in {1..100}; do
  [[ "$(adb shell getprop sys.boot_completed | tr -d '\r')" == 1 ]] && break
  kill -0 "$emulator_pid" || { tail -n 40 "$logs/emulador.log"; exit 1; }
  sleep 2
done
[[ "$(adb shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]
abi="$(adb shell getprop ro.product.cpu.abilist | tr -d '\r')"
echo "Android API $(adb shell getprop ro.build.version.sdk | tr -d '\r') · ABIs $abi"
if [[ ",$abi," != *,arm64-v8a,* ]]; then
  echo "::error::A imagem de teste não anuncia a tradução arm64-v8a. Nenhum resultado de execução deste APK pode ser confirmado."
  exit 1
fi
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb shell settings put secure immersive_mode_confirmations confirmed
adb install --no-streaming "$apk"
activity="$(adb shell cmd package resolve-activity --brief "$pkg" | tr -d '\r' | tail -1)"
[[ "$activity" == "$pkg/"* ]]
adb logcat -c
adb shell am start -W -n "$activity"
wait_marker() {
  local marker="$1"
  for tick in {1..80}; do
    if adb logcat -d -s godot:V Godot:V | grep -F "$marker" > /dev/null; then return 0; fi
    sleep 1
  done
  adb exec-out screencap -p > "$logs/tempo-esgotado.png"
  echo "::error::A execução não alcançou $marker"
  return 1
}
wait_marker VALE_UI_TITULO
python3 -c 'from PIL import Image' || python3 -m pip install --quiet Pillow==11.3.0
# Find the actual primary button on the rendered game surface after Android rotates.
# Scan broad amber runs within the left-hand menu, excluding sky and type outlines.
for tick in {1..24}; do
  adb exec-out screencap -p > "$logs/menu.png"
  if button="$(python3 - "$logs/menu.png" <<'PY'
from PIL import Image
import sys
im=Image.open(sys.argv[1]).convert("RGB")
w,h=im.size
if w <= h: raise SystemExit(1)
scale=min(w/1152,h/648)
pixels=im.load()
rows=[]
for y in range(int(h*.37),int(h*.84),2):
    start=None
    for x in range(int(40*scale),min(w,int(475*scale))):
        r,g,b=pixels[x,y]
        hit=abs(r-237)<14 and abs(g-186)<14 and abs(b-120)<14
        if hit and start is None: start=x
        if not hit and start is not None:
            if x-start > 250*scale: rows.append((y,start,x))
            start=None
if len(rows)<2: raise SystemExit(1)
y,lo,hi=rows[len(rows)//2]
print((lo+hi)//2,y)
PY
)"; then break; fi
  sleep 1
done
[[ -n "$button" ]] || { echo 'Botão Nova travessia ausente na imagem capturada.'; exit 1; }
read -r bx by <<< "$button"
adb shell input tap "$bx" "$by"
wait_marker VALE_UI_JOGO
sleep 3
adb exec-out screencap -p > "$logs/jogo.png"
bounds="$(python3 - "$logs/jogo.png" <<'PY'
from PIL import Image
import sys
w,h=Image.open(sys.argv[1]).size
print(round(w*.15), round(h*.69), round(w*.15), round(h*.48))
PY
)"
read -r x1 y1 x2 y2 <<< "$bounds"
adb shell input touchscreen swipe "$x1" "$y1" "$x2" "$y2" 650
adb shell input keyevent KEYCODE_M
sleep 2
adb exec-out screencap -p > "$logs/mapa.png"
python3 - "$logs/mapa.png" <<'PY'
from PIL import Image
import sys
im=Image.open(sys.argv[1]).convert("RGB")
sample=im.resize((150,80),Image.Resampling.NEAREST)
hits=sum(abs(r-227)<12 and abs(g-223)<12 and abs(b-200)<12 for r,g,b in sample.getdata())
if hits < 400: raise SystemExit("O painel de papel do mapa não apareceu após M.")
PY
adb shell input keyevent KEYCODE_BACK
sleep 2
adb shell pidof "$pkg"
adb logcat -d -s godot:V Godot:V AndroidRuntime:E libc:F > "$logs/jogo.log"
if grep -E 'SCRIPT ERROR|Parse Error|FATAL EXCEPTION|Fatal signal' "$logs/jogo.log"; then exit 1; fi
echo 'ANDROID_TRAVESSIA_OK'
