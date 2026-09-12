#!/usr/bin/env bash

set -e

crontab -r 2>/dev/null || true

unset HOMEBREW_CACHE HOMEBREW_LOGS
# Scheduled jobs have no usable SSH agent. Avoid global Git URL rewrites that
# turn public GitHub HTTPS Cask sources into SSH fetches.
export GIT_CONFIG_GLOBAL=/dev/null
autoupdate_root="$(brew --repository domt4/autoupdate)"
for file in "$autoupdate_root"/lib/autoupdate/{delete,start,stop}.rb; do
  perl -0pi -e 's{quiet_system "/bin/launchctl", "(load|unload)", Autoupdate::Core\.plist}{SystemCommand.run "/bin/launchctl", args: ["$1", Autoupdate::Core.plist.to_s]}g; s{Utils\.system_command}{SystemCommand.run}g' "$file"
done

brew autoupdate delete 2>/dev/null || true
brew autoupdate start 604800 --upgrade --leaves-only --cleanup --greedy

# Plugin couples RunAtLoad to --immediate. Enable it only after job is loaded:
# next login runs autoupdate, while this installer run cannot race Homebrew.
autoupdate_plist="$HOME/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist"
if [[ -f "$autoupdate_plist" ]]; then
  /usr/libexec/PlistBuddy -c 'Add :RunAtLoad bool true' "$autoupdate_plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c 'Set :RunAtLoad true' "$autoupdate_plist"
fi

# autoupdate writes its own minimal runner and does not retain this script's
# environment. Keep public GitHub Cask fetches on HTTPS in that runner.
autoupdate_runner="$HOME/Library/Application Support/com.github.domt4.homebrew-autoupdate/brew_autoupdate"
if [[ -f "$autoupdate_runner" ]]; then
  perl -0pi -e 's{(export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1\n)}{$1export GIT_CONFIG_GLOBAL=/dev/null\n}' "$autoupdate_runner"
fi
