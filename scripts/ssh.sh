#!/usr/bin/env bash

# set -x # for debugging; prints executed commands
set -e

PRIVATE_KEY=~/.ssh/id_ed25519
PUBLIC_KEY=${PRIVATE_KEY}.pub

echo ${PUBLIC_KEY}

if [ -f ~/.ssh/id_ed25519 ]; then
  echo -e '\n🔑  Found existing SSH key\n'
else
  echo -e '\n🔒  Generating new SSH key\n'
  ssh-keygen -t ed25519 -C "brandonl@users.noreply.github.com"

  echo -e '\n🕵️  Starting the SSH agent\n'
  eval "$(ssh-agent -s)"

  echo -e '\n🔐  Adding your key to the SSH agent\n'
  ssh-add --apple-use-keychain ${PRIVATE_KEY}

  echo -e '\n📋  Copying your public key to the clipboard\n'
  cat ${PUBLIC_KEY} | pbcopy
fi

if ! gh auth status; then
  echo -e '🔓  Login to GitHub\n'
  gh auth login
fi

echo -e '📦  Adding key file to GitHub\n'
gh ssh-key add ${PUBLIC_KEY} --title "Personal Laptop"

echo -e '📋  Listing all keys on GitHub\n'
gh ssh-key list
