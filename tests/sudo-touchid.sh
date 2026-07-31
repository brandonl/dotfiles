#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

pam_dir="$test_root/pam.d"
mkdir -p "$pam_dir"

cat >"$pam_dir/sudo" <<'EOF'
# sudo: auth account password session
auth       include        sudo_local
EOF

cat >"$pam_dir/sudo_local" <<'EOF'
# sudo_local: local sudo config
#auth       sufficient     pam_tid.so
EOF

SUDO_TOUCHID_PAM_DIR="$pam_dir" \
SUDO_TOUCHID_SUDO="" \
SUDO_TOUCHID_VERIFY=0 \
  "$repo_root/scripts/sudo-touchid.sh"

pam_line='^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)'
[[ "$(grep -Ec "$pam_line" "$pam_dir/sudo_local")" == "1" ]]

before="$(shasum "$pam_dir/sudo_local")"
SUDO_TOUCHID_PAM_DIR="$pam_dir" \
SUDO_TOUCHID_SUDO="" \
SUDO_TOUCHID_VERIFY=0 \
  "$repo_root/scripts/sudo-touchid.sh"
after="$(shasum "$pam_dir/sudo_local")"

[[ "$before" == "$after" ]]

fake_sudo="$test_root/fake-sudo"
cat >"$fake_sudo" <<'EOF'
#!/usr/bin/env bash
exit 99
EOF
chmod +x "$fake_sudo"

SUDO_TOUCHID_PAM_DIR="$pam_dir" \
SUDO_TOUCHID_SUDO="$fake_sudo" \
  "$repo_root/scripts/sudo-touchid.sh"
