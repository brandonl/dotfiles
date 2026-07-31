#!/usr/bin/env bash

set -e

for app in "$@"; do
  killall "$app" >/dev/null 2>&1 || true
done
