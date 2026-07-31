#!/usr/bin/env bash

set -euo pipefail

pam_dir="${SUDO_TOUCHID_PAM_DIR:-/etc/pam.d}"
sudo_command="${SUDO_TOUCHID_SUDO-sudo}"
verify="${SUDO_TOUCHID_VERIFY:-if-changed}"
changed=0
sudo_pam="$pam_dir/sudo"
sudo_local="$pam_dir/sudo_local"
sudo_local_template="$pam_dir/sudo_local.template"
pam_line='auth       sufficient     pam_tid.so'
pam_pattern='^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)'

run_as_root() {
  if [[ -n "$sudo_command" ]]; then
    "$sudo_command" "$@"
  else
    "$@"
  fi
}

if ! grep -Eq '^[[:space:]]*auth[[:space:]]+include[[:space:]]+sudo_local([[:space:]]|$)' "$sudo_pam"; then
  echo "error: $sudo_pam does not include sudo_local; refusing to modify sudo PAM" >&2
  exit 1
fi

if ! grep -Eq "$pam_pattern" "$sudo_local" 2>/dev/null; then
  if [[ -n "$sudo_command" ]]; then
    "$sudo_command" --validate
  fi

  source_file=/dev/null
  if [[ -f "$sudo_local" ]]; then
    source_file="$sudo_local"
  elif [[ -f "$sudo_local_template" ]]; then
    source_file="$sudo_local_template"
  fi

  output="$(mktemp)"
  trap 'rm -f "$output"' EXIT
  awk -v pam_line="$pam_line" '
    /^[[:space:]]*#[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)/ && !enabled {
      print pam_line
      enabled = 1
      next
    }
    { print }
    END {
      if (!enabled) {
        print pam_line
      }
    }
  ' "$source_file" >"$output"

  run_as_root install -m 0644 "$output" "$sudo_local"
  changed=1
  echo "Touch ID enabled for sudo."
fi

if [[ -n "$sudo_command" ]] && {
  [[ "$verify" == "1" ]] || [[ "$verify" == "if-changed" && "$changed" == "1" ]]
}; then
  echo "Verifying sudo with Touch ID..."
  "$sudo_command" -k
  "$sudo_command" --validate
fi
