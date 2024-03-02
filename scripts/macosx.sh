#!/usr/bin/env bash

set -e

# Ask for administrator password upfront
sudo --validate

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

# Restart applications
killall Dock
killall Finder
killall Safari

# Install Xcode Command-Line Tools
if ! xcode-select -p ; then
	xcode-select --install
	exit 0
fi

# Switch to zsh shell
if ! echo $SHELL | grep zsh; then
	chsh -s $(which zsh)
fi

# # Login Items
osascript -e 'tell application "System Events" to make login item at end with properties { name: "Clocker", path: "/Applications/Clocker.app", hidden: false }'
osascript -e 'tell application "System Events" to make login item at end with properties { name: "Rectangle", path: "/Applications/Rectangle.app", hidden: false }'
osascript -e 'tell application "System Events" to make login item at end with properties { name: "Rectangle", path: "/Applications/SaneSideButtons.app", hidden: false }'

# crontab ./cron.txt
