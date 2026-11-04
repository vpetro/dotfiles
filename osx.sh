#!/bin/bash

set -u

DRY_RUN=0
FAILED=0
WALLPAPER="${DOTFILES_WALLPAPER:-$HOME/Pictures/Wallpapers/vladstudio_cantsleep_1600x1200_signed.jpg}"
WALLPAPER_SHA256=8afdf2db46676024913840f1dcff9e984516b2df4e82957597354df6c3155fbc

DOCK_APPS=(
    "Google Chrome.app"
    "Firefox Nightly.app"
    "Slack.app"
)
if [[ -n "${DOTFILES_DOCK_APPS:-}" ]]; then
    IFS=: read -r -a DOCK_APPS <<< "$DOTFILES_DOCK_APPS"
fi
DOCK_FOLDER="$HOME/Downloads"
APP_DIRS=(/Applications "$HOME/Applications" /System/Applications)
if [[ -n "${DOTFILES_APP_DIRS:-}" ]]; then
    IFS=: read -r -a APP_DIRS <<< "$DOTFILES_APP_DIRS"
fi

usage() {
    echo "usage: $(basename "$0") [-n|--dry-run] [--wallpaper PATH]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        --wallpaper)
            if [[ $# -lt 2 ]]; then
                usage >&2
                exit 2
            fi
            shift
            WALLPAPER="$1"
            ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '  would run        '
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    if ! "$@"; then
        printf '  FAILED           '
        printf ' %q' "$@"
        printf '\n'
        FAILED=$((FAILED + 1))
        return 1
    fi
}

has_full_disk_access() {
    head -c 1 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" >/dev/null 2>&1 ||
        ls "$HOME/Library/Safari" >/dev/null 2>&1
}

xml_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

file_url() {
    local path="$1" out="" c n i
    local LC_ALL=C
    for ((i = 0; i < ${#path}; i++)); do
        c="${path:i:1}"
        case "$c" in
            [A-Za-z0-9/._~-]) out+="$c" ;;
            *)
                printf -v n '%d' "'$c"
                printf -v c '%%%02X' "$((n & 255))"
                out+="$c"
                ;;
        esac
    done
    printf 'file://%s/' "$out"
}

app_tile() {
    local path="$1"
    printf '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>%s</string></dict><key>tile-type</key><string>file-tile</string></dict>' \
        "$(xml_escape "$(file_url "$path")")" \
        "$(xml_escape "$(basename "$path" .app)")"
}

folder_tile() {
    local path="$1" arrangement="$2" displayas="$3" showas="$4"
    printf '<dict><key>tile-data</key><dict><key>arrangement</key><integer>%s</integer><key>displayas</key><integer>%s</integer><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>%s</string><key>file-type</key><integer>2</integer><key>showas</key><integer>%s</integer></dict><key>tile-type</key><string>directory-tile</string></dict>' \
        "$arrangement" "$displayas" \
        "$(xml_escape "$(file_url "$path")")" \
        "$(xml_escape "$(basename "$path")")" \
        "$showas"
}

find_app() {
    local rel="$1" dir
    for dir in "${APP_DIRS[@]}"; do
        if [[ -d "$dir/$rel" ]]; then
            printf '%s' "$dir/$rel"
            return 0
        fi
    done
    return 1
}

startup_sound() {
    run sudo nvram StartupMute=%01
}

global_prefs() {
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    run defaults write NSGlobalDomain KeyRepeat -int 2
    run defaults write NSGlobalDomain InitialKeyRepeat -int 15
    run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    run defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
    run defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
    run defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
}

finder_prefs() {
    run defaults write com.apple.finder ShowPathbar -bool true
    run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    run defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
    run defaults write com.apple.finder WarnOnEmptyTrash -bool false
    run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    run chflags nohidden "$HOME/Library"
}

disk_images() {
    run defaults write com.apple.frameworks.diskimages skip-verify -bool true
    run defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    run defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
}

hotkeys() {
    run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 52 \
        '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>100</integer><integer>2</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>'
}

dock() {
    local tiles=() others=() rel path

    for rel in "${DOCK_APPS[@]}"; do
        if path="$(find_app "$rel")"; then
            echo "  pin               $path"
            tiles+=("$(app_tile "$path")")
        else
            echo "  missing, skipped  $rel (searched: ${APP_DIRS[*]})"
        fi
    done
    if [[ -d "$DOCK_FOLDER" ]]; then
        echo "  pin               $DOCK_FOLDER (stack, fan, by date added)"
        others+=("$(folder_tile "$DOCK_FOLDER" 2 0 1)")
    else
        echo "  missing, skipped  $DOCK_FOLDER"
    fi

    run defaults write com.apple.dock persistent-apps -array ${tiles[@]+"${tiles[@]}"}
    run defaults write com.apple.dock persistent-others -array ${others[@]+"${others[@]}"}
    run defaults write com.apple.dock orientation -string left
    run defaults write com.apple.dock autohide -bool true
    run defaults write com.apple.dock magnification -bool true
    run defaults write com.apple.dock tilesize -float 40
    run defaults write com.apple.dock largesize -float 76
    run defaults write com.apple.dock show-recents -bool true
    run defaults write com.apple.dock showDesktopGestureEnabled -bool false
    run defaults write com.apple.dock wvous-tr-corner -int 5
    run defaults write com.apple.dock wvous-tr-modifier -int 0
    run defaults write com.apple.dock wvous-br-corner -int 14
    run defaults write com.apple.dock wvous-br-modifier -int 0
    run defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
    run defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
    run killall Dock
}

trackpad() {
    run defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    run defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 2
    run defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool false
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadPinch -bool false
    run defaults -currentHost write NSGlobalDomain com.apple.trackpad.pinchGesture -bool false
    run defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool false
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRotate -bool false
    run defaults -currentHost write NSGlobalDomain com.apple.trackpad.rotateGesture -bool false
    run defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 0
    run defaults -currentHost write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 0
    run defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 0
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 0
    run defaults -currentHost write NSGlobalDomain com.apple.trackpad.fourFingerPinchSwipeGesture -int 0
    run defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 0
    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -int 0
    run defaults -currentHost write NSGlobalDomain com.apple.trackpad.fiveFingerPinchSwipeGesture -int 0
}

wallpaper() {
    if [[ ! -f "$WALLPAPER" ]]; then
        echo "  skip (no image)   $WALLPAPER"
        return
    fi
    WALLPAPER="$(cd "$(dirname "$WALLPAPER")" && pwd)/$(basename "$WALLPAPER")"
    local sum
    sum="$(shasum -a 256 "$WALLPAPER" | cut -d' ' -f1)"
    if [[ "$sum" == "$WALLPAPER_SHA256" ]]; then
        echo "  image             $WALLPAPER (sha256 matches)"
    else
        echo "  image             $WALLPAPER (sha256 differs from the recorded image)"
    fi
    run osascript \
        -e 'on run argv' \
        -e 'tell application "System Events" to tell every desktop to set picture to (item 1 of argv)' \
        -e 'end run' \
        "$WALLPAPER"
}

no_full_disk_access() {
    echo "  skip (no Full Disk Access: grant it to this terminal in System Settings > Privacy & Security > Full Disk Access, then re-run)"
}

safari() {
    if ! has_full_disk_access; then
        no_full_disk_access
        return
    fi
    run defaults write com.apple.Safari UniversalSearchEnabled -bool false
    run defaults write com.apple.Safari SuppressSearchSuggestions -bool true
    run defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
    run defaults write com.apple.Safari HomePage -string "about:blank"
    run defaults write com.apple.Safari ShowFavoritesBar -bool false
    run defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    run defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
    run defaults write com.apple.Safari IncludeDevelopMenu -bool true
    run defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    run defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
}

accessibility() {
    if ! has_full_disk_access; then
        no_full_disk_access
        return
    fi
    run defaults write com.apple.universalaccess reduceTransparency -bool true
}

section() {
    echo ""
    echo "=== $1 ==="
}

if [[ $DRY_RUN -eq 1 ]]; then
    echo "dry run: nothing will be changed"
fi

section "startup sound"; startup_sound
section "keyboard, text, appearance"; global_prefs
section "finder"; finder_prefs
section "disk images"; disk_images
section "keyboard shortcuts"; hotkeys
section "dock"; dock
section "trackpad"; trackpad
section "wallpaper"; wallpaper
section "safari"; safari
section "accessibility"; accessibility

echo ""
if [[ $DRY_RUN -eq 1 ]]; then
    echo "dry run: nothing was changed"
    exit 0
fi
run killall Finder
if [[ $FAILED -gt 0 ]]; then
    echo "done with $FAILED failed command(s)"
    exit 1
fi
echo "Done. Note that some of these changes require a logout/restart to take effect."
