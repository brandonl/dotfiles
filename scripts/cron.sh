#!/usr/bin/env bash

# Update brew
brew update

# Upgrade all brew packages
brew upgrade

# Remove old versions of packages
brew cleanup
brew cask cleanup

/usr/bin/osascript -e "display notification \"Cron finished updating Brew\" with title \"Brew Update\""
