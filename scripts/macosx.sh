#!/usr/bin/env bash

set -e

# Ask for administrator password upfront
sudo --validate

ensure_sudo_touchid() {
  local sudo_local=/etc/pam.d/sudo_local
  local pam_line='auth       sufficient     pam_tid.so'

  if [[ -f "$sudo_local" ]] && grep -q 'pam_tid' "$sudo_local"; then
    return 0
  fi

  if [[ -f "$sudo_local" ]]; then
    printf '%s\n' "$pam_line" | sudo tee -a "$sudo_local" >/dev/null
  else
    sudo tee "$sudo_local" >/dev/null <<'EOF'
# sudo_local: local sudo config
auth       sufficient     pam_tid.so
EOF
  fi
}

ensure_sudo_touchid

defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain InitialKeyRepeat -int 12
defaults write NSGlobalDomain KeyRepeat -int 1
# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv
# Show the ~/Library folder.
chflags nohidden ~/Library
defaults write com.apple.dock "show-recents" -bool false
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
brew analytics off

# Restart applications
killall Dock > /dev/null 2>&1
killall Finder > /dev/null 2>&1
killall iTerm2 > /dev/null 2>&1
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
