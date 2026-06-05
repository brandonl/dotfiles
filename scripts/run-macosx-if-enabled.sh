#!/usr/bin/env bash

set -e

if [[ "${DOTFILES_WITH_MACOSX:-0}" == "1" ]]; then
  exec ./scripts/macosx.sh
fi
