#!/usr/bin/env bash

set -e

crontab -r 2>/dev/null || true

brew autoupdate stop 2>/dev/null || true
brew autoupdate start 604800 --upgrade --cleanup --greedy --immediate
