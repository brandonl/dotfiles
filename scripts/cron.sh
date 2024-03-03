#!/usr/bin/env bash

set -e

/usr/bin/osascript -e "display notification \"Updating Brew starting...\" with title \"Crontab\""

. "$HOME/.keychain/$(hostname -f)-sh"

# Update brew
/opt/homebrew/bin/brew update

# Upgrade all brew packages
/opt/homebrew/bin/brew upgrade

# Remove old versions of packages
/opt/homebrew/bin/brew cleanup
/opt/homebrew/bin/brew cleanup cask

/usr/bin/osascript -e "display notification \"Updating Brew finished; check results with mail\" with title \"Crontab\""
