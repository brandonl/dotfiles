#!/usr/bin/env bash

set -euo pipefail

# Remove only a legacy Homebrew autoupdate cron entry; preserve unrelated jobs.
current_crontab="$(crontab -l 2>/dev/null || true)"
if [[ -n "$current_crontab" ]]; then
  filtered_crontab="$(printf '%s\n' "$current_crontab" | awk '!/brew[[:space:]]+autoupdate/')"
  if [[ "$filtered_crontab" != "$current_crontab" ]]; then
    if [[ -n "$filtered_crontab" ]]; then
      printf '%s\n' "$filtered_crontab" | crontab -
    else
      crontab -r
    fi
  fi
fi

unset HOMEBREW_CACHE HOMEBREW_LOGS
# Scheduled jobs have no usable SSH agent. Avoid global Git URL rewrites that
# turn public GitHub HTTPS Cask sources into SSH fetches.
export GIT_CONFIG_GLOBAL=/dev/null
export HOMEBREW_NO_AUTO_UPDATE=1
autoupdate_root="$(brew --repository domt4/autoupdate)"
autoupdate_files=(
  lib/autoupdate/delete.rb
  lib/autoupdate/start.rb
  lib/autoupdate/stop.rb
)

# The tap's compatibility edits are needed only while creating the launchd
# job. Leaving them in the tap makes the next `brew update` stash those edits;
# if upstream changed the same lines, Git writes conflict markers into Ruby.
for file in "${autoupdate_files[@]}"; do
  if ! git -C "$autoupdate_root" diff --quiet -- "$file" ||
    ! git -C "$autoupdate_root" diff --cached --quiet -- "$file"; then
    echo "[x] Autoupdate tap has local edits in $file; refusing to overwrite them" >&2
    exit 1
  fi
done

autoupdate_backup="$(mktemp -d "${TMPDIR:-/tmp}/brew-autoupdate.XXXXXX")"
backup_complete=0
restore_autoupdate_sources() {
  local exit_status=$?
  trap - EXIT

  if (( backup_complete )); then
    for file in "${autoupdate_files[@]}"; do
      cp -p "$autoupdate_backup/$file" "$autoupdate_root/$file" || exit_status=1
    done
  fi

  /bin/rm -rf "$autoupdate_backup" || exit_status=1
  return "$exit_status"
}
trap restore_autoupdate_sources EXIT

for file in "${autoupdate_files[@]}"; do
  mkdir -p "$autoupdate_backup/$(dirname "$file")"
  cp -p "$autoupdate_root/$file" "$autoupdate_backup/$file"
done
backup_complete=1

for file in "${autoupdate_files[@]}"; do
  perl -0pi -e 's{SystemCommand\.quiet_system "/bin/launchctl", "(load|unload)", Autoupdate::Core\.plist}{SystemCommand.run "/bin/launchctl", args: ["$1", Autoupdate::Core.plist.to_s]}g; s{Utils\.system_command}{SystemCommand.run}g' "$autoupdate_root/$file"
  if rg -n '^(<<<<<<<|=======|>>>>>>>)' "$autoupdate_root/$file"; then
    echo "[x] Merge markers remain in $file after compatibility patch" >&2
    exit 1
  fi
  if ! rg -q '^[[:space:]]*SystemCommand\.run "/bin/launchctl"' "$autoupdate_root/$file"; then
    echo "[x] Expected launchctl compatibility call missing from $file" >&2
    exit 1
  fi
done

autoupdate_plist="$HOME/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist"
if [[ -f "$autoupdate_plist" ]]; then
  brew autoupdate delete
fi
brew autoupdate start 604800 --upgrade --leaves-only --cleanup --greedy

# Plugin couples RunAtLoad to --immediate. Enable it only after job is loaded:
# next login runs autoupdate, while this installer run cannot race Homebrew.
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
