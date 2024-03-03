#!/usr/bin/env bash

# Update brew
brew update

# Upgrade all brew packages
brew upgrade

# Remove old versions of packages
brew cleanup
brew cleanup --cask

/usr/bin/osascript -e "display notification \"Cron finished updating Brew, check results with `mail`\" with title \"Brew Update\""
