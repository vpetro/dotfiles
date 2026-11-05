#!/bin/bash

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../osx.sh"
PASS=0
FAIL=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STUBS="$TMP/stubs"
FAKE_HOME="$TMP/home dir&x"
APPS="$TMP/apps"
TCC_DB="$FAKE_HOME/Library/Application Support/com.apple.TCC/TCC.db"
mkdir -p "$STUBS" "$FAKE_HOME/Downloads" "$(dirname "$TCC_DB")" "$FAKE_HOME/Pictures/Wallpapers" \
    "$APPS/Google Chrome.app" "$APPS/Firefox Nightly.app" "$APPS/Slack.app" "$APPS/Vendor/Extra Tool.app"
head -c 4096 /dev/urandom > "$FAKE_HOME/Pictures/Wallpapers/vladstudio_cantsleep_1600x1200_signed.jpg"
head -c 64 /dev/urandom > "$TCC_DB"

cat > "$STUBS/log.sh" <<'EOF'
printf '%s' "$(basename "$0")" >> "$FAKE_LOG"
printf ' %q' "$@" >> "$FAKE_LOG"
printf '\n' >> "$FAKE_LOG"
EOF

cat > "$STUBS/defaults" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/log.sh"
host=""
if [[ "${1:-}" == "-currentHost" ]]; then
    host="currentHost."
    shift
fi
verb="$1"
shift
if [[ "$verb" != "write" ]]; then
    echo "stub defaults: unsupported verb $verb" >&2
    exit 1
fi
domain="$1"
key="$2"
shift 2
mkdir -p "$FAKE_STORE/$host$domain"
printf '%s\n' "$@" > "$FAKE_STORE/$host$domain/$key"
EOF

cat > "$STUBS/osascript" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/log.sh"
if [[ "${FAKE_OSASCRIPT_FAIL:-0}" == 1 ]]; then
    exit 1
fi
exit 0
EOF

for name in sudo killall chflags; do
    cat > "$STUBS/$name" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/log.sh"
EOF
done
chmod +x "$STUBS"/defaults "$STUBS"/osascript "$STUBS"/sudo "$STUBS"/killall "$STUBS"/chflags

export FAKE_LOG FAKE_STORE
RUN_APP_DIRS="$APPS:$TMP/apps2"
scenario() {
    FAKE_LOG="$TMP/$1.log"
    FAKE_STORE="$TMP/$1.store"
    : > "$FAKE_LOG"
    rm -rf "$FAKE_STORE"
    mkdir -p "$FAKE_STORE"
}

run_script() {
    OUT="$TMP/out.txt"
    HOME="$FAKE_HOME" PATH="$STUBS:$PATH" DOTFILES_APP_DIRS="$RUN_APP_DIRS" bash "$SCRIPT" "$@" > "$OUT" 2>&1
    STATUS=$?
    return "$STATUS"
}

ok() { PASS=$((PASS + 1)); }
bad() {
    FAIL=$((FAIL + 1))
    echo "FAIL: $1"
    if [[ $# -gt 1 ]]; then
        printf '      %s\n' "${@:2}"
    fi
}

assert_eq() {
    if [[ "$2" == "$3" ]]; then
        ok
    else
        bad "$1" "expected: $3" "actual:   $2"
    fi
}
assert_file_contains() {
    if grep -qF -- "$3" "$2"; then
        ok
    else
        bad "$1" "missing: $3" "in: $2"
    fi
}
assert_file_lacks() {
    if grep -qF -- "$3" "$2"; then
        bad "$1" "unexpected: $3" "in: $2"
    else
        ok
    fi
}
assert_missing() {
    if [[ -e "$2" ]]; then
        bad "$1" "exists: $2"
    else
        ok
    fi
}
labels_of() {
    grep -o '<key>file-label</key><string>[^<]*' "$1" | sed 's/.*<string>//' | tr '\n' ','
}
count_tiles() {
    grep -o '<dict><key>tile-data</key>' "$1" | wc -l | tr -d ' '
}

echo "--- dry run makes no changes ---"
scenario dry
run_script --dry-run
assert_eq "dry run exits 0" "$STATUS" 0
assert_file_contains "dry run announces itself" "$OUT" "Dry run complete. No settings were changed."
assert_file_contains "dry run shows the planned dock pins" "$OUT" "Dock item: $APPS/Google Chrome.app"
assert_file_contains "dry run shows a planned command" "$OUT" "Would run: defaults write com.apple.dock orientation -string left"
assert_eq "dry run runs no commands" "$(wc -l < "$FAKE_LOG" | tr -d ' ')" 0
assert_eq "dry run writes nothing" "$(find "$FAKE_STORE" -type f | wc -l | tr -d ' ')" 0

echo "--- apply pins the dock in order with encoded urls ---"
scenario apply
run_script
assert_eq "apply exits 0" "$STATUS" 0
assert_eq "three apps pinned in order" "$(labels_of "$FAKE_STORE/com.apple.dock/persistent-apps")" "Google Chrome,Firefox Nightly,Slack,"
assert_eq "three app tiles" "$(count_tiles "$FAKE_STORE/com.apple.dock/persistent-apps")" 3
assert_file_contains "app path is percent-encoded" "$FAKE_STORE/com.apple.dock/persistent-apps" "<string>file://$APPS/Google%20Chrome.app/</string>"
assert_file_contains "downloads url uses the running user's home" "$FAKE_STORE/com.apple.dock/persistent-others" "<string>file://$TMP/home%20dir%26x/Downloads/</string>"
assert_file_contains "downloads tile keeps stack/fan/date-added" "$FAKE_STORE/com.apple.dock/persistent-others" "<key>arrangement</key><integer>2</integer><key>displayas</key><integer>0</integer>"
assert_file_contains "downloads tile shows as fan" "$FAKE_STORE/com.apple.dock/persistent-others" "<key>showas</key><integer>1</integer>"
assert_eq "one folder tile" "$(count_tiles "$FAKE_STORE/com.apple.dock/persistent-others")" 1
assert_file_lacks "no bookmark blobs written" "$FAKE_STORE/com.apple.dock/persistent-apps" "<key>book</key>"
assert_eq "dock orientation left" "$(tr '\n' ' ' < "$FAKE_STORE/com.apple.dock/orientation")" "-string left "
assert_eq "hot corner top-right is screen saver" "$(tr '\n' ' ' < "$FAKE_STORE/com.apple.dock/wvous-tr-corner")" "-int 5 "
assert_file_contains "dock restarted" "$FAKE_LOG" "killall Dock"
assert_file_contains "finder restarted" "$FAKE_LOG" "killall Finder"
assert_file_contains "startup chime muted via sudo" "$FAKE_LOG" "sudo nvram StartupMute=%01"
assert_file_contains "library unhidden in fake home" "$FAKE_LOG" "chflags nohidden $(printf '%q' "$FAKE_HOME/Library")"
assert_file_contains "wallpaper path passed intact to osascript" "$FAKE_LOG" "osascript -e on\\ run\\ argv -e tell\\ application\\ \\\"System\\ Events\\\"\\ to\\ tell\\ every\\ desktop\\ to\\ set\\ picture\\ to\\ \\(item\\ 1\\ of\\ argv\\) -e end\\ run $(printf '%q' "$FAKE_HOME/Pictures/Wallpapers/vladstudio_cantsleep_1600x1200_signed.jpg")"
assert_file_contains "checksum mismatch is reported" "$OUT" "Wallpaper checksum differs from the saved image."
assert_file_contains "hotkey 52 disabled with its key combo kept" "$FAKE_STORE/com.apple.symbolichotkeys/AppleSymbolicHotKeys" "<key>enabled</key><false/><key>value</key>"
assert_eq "currentHost tap behavior written" "$(tr '\n' ' ' < "$FAKE_STORE/currentHost.NSGlobalDomain/com.apple.mouse.tapBehavior")" "-int 2 "
assert_file_contains "safari written with full disk access" "$FAKE_STORE/com.apple.Safari/HomePage" "about:blank"
assert_file_contains "reduce transparency written" "$FAKE_STORE/com.apple.universalaccess/reduceTransparency" "true"

echo "--- repeat application does not duplicate dock entries ---"
run_script
assert_eq "second apply exits 0" "$STATUS" 0
assert_eq "still three app tiles" "$(count_tiles "$FAKE_STORE/com.apple.dock/persistent-apps")" 3
assert_eq "still one folder tile" "$(count_tiles "$FAKE_STORE/com.apple.dock/persistent-others")" 1
assert_eq "persistent-apps written once per run" "$(grep -c 'persistent-apps' "$FAKE_LOG")" 2
assert_eq "both persistent-apps writes identical" "$(grep 'persistent-apps' "$FAKE_LOG" | sort -u | wc -l | tr -d ' ')" 1
assert_file_lacks "array-add never used" "$FAKE_LOG" "array-add"

echo "--- missing app is skipped, not pinned ---"
scenario missing_app
rmdir "$APPS/Slack.app"
run_script
assert_eq "missing app exits 0" "$STATUS" 0
assert_file_contains "missing app reported" "$OUT" "Skipped missing Dock item: Slack.app"
assert_eq "two apps pinned in order" "$(labels_of "$FAKE_STORE/com.apple.dock/persistent-apps")" "Google Chrome,Firefox Nightly,"
mkdir "$APPS/Slack.app"

echo "--- dock app list override with a nested app path ---"
scenario dock_override
DOTFILES_DOCK_APPS="Slack.app:Vendor/Extra Tool.app" run_script
assert_eq "dock override exits 0" "$STATUS" 0
assert_eq "override list pinned in order" "$(labels_of "$FAKE_STORE/com.apple.dock/persistent-apps")" "Slack,Extra Tool,"
assert_file_contains "nested app path is percent-encoded" "$FAKE_STORE/com.apple.dock/persistent-apps" "<string>file://$APPS/Vendor/Extra%20Tool.app/</string>"

echo "--- all apps missing writes an empty list ---"
scenario no_apps
RUN_APP_DIRS="$TMP/nowhere" run_script
assert_eq "no apps exits 0" "$STATUS" 0
assert_eq "zero app tiles" "$(count_tiles "$FAKE_STORE/com.apple.dock/persistent-apps")" 0
assert_eq "persistent-apps still written as an array" "$(tr '\n' ' ' < "$FAKE_STORE/com.apple.dock/persistent-apps")" "-array "

echo "--- missing wallpaper is skipped ---"
scenario missing_image
run_script --wallpaper "$TMP/nope.jpg"
assert_eq "missing image exits 0" "$STATUS" 0
assert_file_contains "missing image reported" "$OUT" "Wallpaper not found: $TMP/nope.jpg"
assert_file_lacks "osascript not called without an image" "$FAKE_LOG" "osascript"

echo "--- wallpaper override and relative path ---"
scenario override
mkdir -p "$TMP/alt dir"
head -c 100 /dev/urandom > "$TMP/alt dir/pic one.jpg"
( cd "$TMP/alt dir" && run_script --wallpaper "pic one.jpg" )
STATUS=$?
OUT="$TMP/out.txt"
assert_eq "override exits 0" "$STATUS" 0
assert_file_contains "override reports the image" "$OUT" "Wallpaper checksum differs from the saved image. ($TMP/alt dir/pic one.jpg)"
assert_file_contains "relative path resolved to absolute" "$FAKE_LOG" "$(printf '%q' "$TMP/alt dir/pic one.jpg")"
scenario env_override
head -c 100 /dev/urandom > "$TMP/env.jpg"
DOTFILES_WALLPAPER="$TMP/env.jpg" run_script
assert_eq "env override exits 0" "$STATUS" 0
assert_file_contains "env override used" "$FAKE_LOG" "$(printf '%q' "$TMP/env.jpg")"

PRESERVED="$HOME/Pictures/Wallpapers/vladstudio_cantsleep_1600x1200_signed.jpg"
if [[ -f "$PRESERVED" ]]; then
    echo "--- preserved image matches the recorded checksum ---"
    scenario preserved
    run_script --wallpaper "$PRESERVED"
    assert_file_contains "checksum match reported" "$OUT" "Wallpaper checksum matches the saved image. ($PRESERVED)"
else
    echo "--- (skipped: preserved image not present at $PRESERVED) ---"
fi

echo "--- wallpaper failure is reported and the run continues ---"
scenario osa_fail
FAKE_OSASCRIPT_FAIL=1 run_script
assert_eq "failure exits 1" "$STATUS" 1
assert_file_contains "failure printed" "$OUT" "Command failed: osascript"
assert_file_contains "failure count printed" "$OUT" "Setup finished with 1 failed command."
assert_file_contains "later steps still ran" "$FAKE_LOG" "killall Finder"
assert_file_contains "safari still applied after the failure" "$FAKE_STORE/com.apple.Safari/HomePage" "about:blank"

echo "--- without full disk access the protected domains are skipped ---"
scenario no_fda
chmod 000 "$TCC_DB"
run_script
assert_eq "no fda exits 0" "$STATUS" 0
assert_eq "two protected sections skipped" "$(grep -c 'Protected settings skipped' "$OUT")" 2
assert_missing "safari not written without fda" "$FAKE_STORE/com.apple.Safari"
assert_missing "universalaccess not written without fda" "$FAKE_STORE/com.apple.universalaccess"
assert_file_contains "unprotected domains still written" "$FAKE_STORE/com.apple.finder/ShowPathbar" "true"

echo "--- a readable Safari directory also counts as full disk access ---"
scenario fda_safari
mkdir "$FAKE_HOME/Library/Safari"
run_script
assert_eq "safari-probe run exits 0" "$STATUS" 0
assert_file_contains "safari written via the fallback probe" "$FAKE_STORE/com.apple.Safari/HomePage" "about:blank"
assert_file_contains "reduce transparency written via the fallback probe" "$FAKE_STORE/com.apple.universalaccess/reduceTransparency" "true"
rmdir "$FAKE_HOME/Library/Safari"
chmod 644 "$TCC_DB"

echo "--- argument errors ---"
scenario args
run_script --bogus
assert_eq "unknown flag exits 2" "$STATUS" 2
run_script --wallpaper
assert_eq "wallpaper without a path exits 2" "$STATUS" 2
run_script --help
assert_eq "help exits 0" "$STATUS" 0
assert_eq "argument errors change nothing" "$(find "$FAKE_STORE" -type f | wc -l | tr -d ' ')" 0

echo ""
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]
