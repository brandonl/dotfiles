#!/usr/bin/env bash

set -e

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sudo-touchid.sh"

disable_gui_service() {
  local service="$1"
  local target="gui/$(id -u)/${service}"
  launchctl bootout "$target" 2>/dev/null || true
  launchctl disable "$target" 2>/dev/null || true
}

# Unused bundled apps: bootout/disable background agents.
BUNDLED_APP_SERVICES=(
  com.apple.watchlistd              # Stocks
  com.apple.weatherd                # Weather
  com.apple.weather.menu            # Weather menu bar
  com.apple.ScreenTimeAgent         # Screen Time
  com.apple.ScreenTimeSettingsAgent
  com.apple.tipsd                   # Tips
  com.apple.photolibraryd           # Photos
  com.apple.photoanalysisd
  com.apple.cloudphotod
  com.apple.mediastream.mstreamd
  com.apple.mediaanalysisd
)

for service in "${BUNDLED_APP_SERVICES[@]}"; do
  disable_gui_service "$service"
done

defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g AppleIconAppearanceTheme -string ClearLight
defaults write -g AppleShowScrollBars -string Automatic
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain InitialKeyRepeat -int 12
defaults write NSGlobalDomain KeyRepeat -int 1
# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv
# Show the ~/Library folder.
chflags nohidden ~/Library
defaults write com.apple.dock "show-recents" -bool false
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock tilesize -int 56
# Hot corners
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# lock if cursor is in the bottom-left hot corner 13 = lockscreen, 
defaults write com.apple.dock wvous-bl-corner -int 13
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool false
# Avoid create DS_Store to USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Show all hidden files
defaults write com.apple.finder AppleShowAllFiles true
defaults write com.apple.screencapture "location" -string "~/Downloads"
# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false
# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write -g AppleInterfaceStyle -string Dark
defaults write com.apple.WindowManager AppWindowGroupingBehavior -int 1
defaults write com.apple.WindowManager AutoHide -bool true
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false
defaults write com.apple.WindowManager HideDesktop -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write -g com.apple.mouse.scaling -int 2
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -bool false
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonDivision -int 55
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string OneButton
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseHorizontalScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseMomentumScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseVerticalScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse UserPreferences -bool true
defaults write com.apple.AppleMultitouchMouse MouseButtonDivision -int 55
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string OneButton
defaults write com.apple.AppleMultitouchMouse MouseHorizontalScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseMomentumScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchMouse MouseVerticalScroll -bool true
defaults write com.apple.AppleMultitouchMouse UserPreferences -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# Rectangle
defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool false
defaults write com.knollsoft.Rectangle reflowTodo -dict keyCode -int 45 modifierFlags -int 786432
defaults write com.knollsoft.Rectangle subsequentExecutionMode -int 0
defaults write com.knollsoft.Rectangle toggleTodo -dict keyCode -int 11 modifierFlags -int 786432
defaults write com.knollsoft.Rectangle windowSnapping -int 2
defaults write com.knollsoft.Rectangle SUEnableAutomaticChecks -bool false

# Hyperkey
defaults write com.knollsoft.Hyperkey capsLockRemapped -int 2
defaults write com.knollsoft.Hyperkey executeQuickHyperKey -int 1
defaults write com.knollsoft.Hyperkey hyperFlags -int 1966080
defaults write com.knollsoft.Hyperkey keyRemap -int 1
defaults write com.knollsoft.Hyperkey launchOnLogin -bool true
defaults write com.knollsoft.Hyperkey SUEnableAutomaticChecks -bool true

# DockDoor
defaults write com.ethanbills.DockDoor activeAppIndicatorLength -int 37
defaults write com.ethanbills.DockDoor activeAppIndicatorShift -int 0
defaults write com.ethanbills.DockDoor enableCmdTabEnhancements -bool true
defaults write com.ethanbills.DockDoor reopenSettingsAfterRestart -bool false
defaults write com.ethanbills.DockDoor showActiveAppIndicator -bool true
defaults write com.ethanbills.DockDoor SUAutomaticallyUpdate -bool true
defaults write com.ethanbills.DockDoor SUEnableAutomaticChecks -bool true
defaults write com.ethanbills.DockDoor SUSendProfileInfo -bool false

# Clocker stores preferences inside its sandbox container.
clocker_preferences="$HOME/Library/Containers/com.abhishek.Clocker/Data/Library/Preferences/com.abhishek.Clocker"
if [[ -d "$(dirname "$clocker_preferences")" ]]; then
  defaults write "$clocker_preferences" com.abhishek.analyticsOptOut -bool true
  defaults write "$clocker_preferences" com.abhishek.menubarCompactMode -int 0
  defaults write "$clocker_preferences" defaultTheme -int 4
  defaults write "$clocker_preferences" installHomeIndicatorObject -int 1
  defaults write "$clocker_preferences" ShowUpcomingEventView -string NO
  defaults write "$clocker_preferences" startAtLogin -int 1
else
  echo "Clocker preferences unavailable until Clocker has launched once."
fi

# Cotypist
defaults write app.cotypist.Cotypist AnalyticsManager_analyticsDisabled -bool true
defaults write app.cotypist.Cotypist ModelRepository_selectedModel -string gemma-4-E2B-i1-Q4_K_M
defaults write app.cotypist.Cotypist ModelRepository_shouldShowCompletedWordCountInMenuBar -bool false
defaults write app.cotypist.Cotypist TextFieldContextCapture_pasteboardContextEnabled -bool true

brew analytics off

# Restart applications
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/restart-apps.sh" \
  Dock Finder SystemUIServer iTerm2
# killall Safari &> /dev/null

# Install Xcode Command-Line Tools
if ! xcode-select -p ; then
  	echo -e '\n🔒  Installing xcode cli tools\n'
	xcode-select --install
	exit 0
fi

# Switch to zsh shell
if ! echo $SHELL | grep zsh; then
  	echo -e '\n🔒  Switch to ZSH\n'
	chsh -s $(which zsh)
fi

# Login Items
ensure_login_item() {
  local name="$1"
  local path="$2"
  osascript <<EOF
tell application "System Events"
  repeat with li in login items
    if (path of li as text) is "$path" then
      return
    end if
  end repeat
  make login item at end with properties {name:"$name", path:"$path", hidden:false}
end tell
EOF
}

ensure_login_item "1Password" "/Applications/1Password.app"
ensure_login_item "Raycast" "/Applications/Raycast.app"
ensure_login_item "superwhisper" "/Applications/superwhisper.app"
ensure_login_item "Clocker" "/Applications/Clocker.app"
ensure_login_item "Rectangle" "/Applications/Rectangle.app"
ensure_login_item "SaneSideButtons" "/Applications/SaneSideButtons.app"

open -gj -a Clocker
