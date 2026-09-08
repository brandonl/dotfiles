#!/usr/bin/env bash

set -e

crontab -r 2>/dev/null || true

unset HOMEBREW_CACHE HOMEBREW_LOGS
autoupdate_root="$(brew --repository domt4/autoupdate)"
for file in "$autoupdate_root"/lib/autoupdate/{delete,start,stop}.rb; do
  perl -0pi -e 's{quiet_system "/bin/launchctl", "(load|unload)", Autoupdate::Core\.plist}{SystemCommand.run "/bin/launchctl", args: ["$1", Autoupdate::Core.plist.to_s]}g; s{Utils\.system_command}{SystemCommand.run}g' "$file"
done

brew autoupdate delete 2>/dev/null || true
brew autoupdate start 604800 --upgrade --leaves-only --cleanup --greedy --immediate
