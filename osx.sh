#!/bin/sh

sudo nvram StartupMute=%01

defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

-- disable dock always show/autohide shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 52 '{enabled = 0;}'

chflags nohidden ~/Library

if defaults write com.apple.Safari FDAProbe -bool true 2>/dev/null; then
  defaults delete com.apple.Safari FDAProbe 2>/dev/null

  defaults write com.apple.Safari UniversalSearchEnabled -bool false
  defaults write com.apple.Safari SuppressSearchSuggestions -bool true
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
  defaults write com.apple.Safari HomePage -string "about:blank"
  defaults write com.apple.Safari ShowFavoritesBar -bool false
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
  defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

  defaults write com.apple.universalaccess reduceTransparency -bool true
else
  echo "Skipped Safari and accessibility settings: grant Full Disk Access to this terminal (System Settings > Privacy & Security > Full Disk Access) and re-run."
fi

killall Finder

echo "Done. Note that some of these changes require a logout/restart to take effect."


