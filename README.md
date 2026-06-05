# Dotfiles

Personal macOS setup managed with [dotbot](https://github.com/anishathalye/dotbot).

## Quick start

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install
```

Re-run `./install` after pulling changes. Dotbot relinks files in place.

## What `./install` does

- Installs and upgrades Homebrew packages from `Brewfile` (`brew bundle install --upgrade`)
- Initializes git submodules (Oh My Zsh, plugins, dotbot)
- Symlinks dotfiles into `$HOME` (`~/.zshrc`, `~/.config/*`, `~/.ssh/*`, git config, etc.)
- Installs fonts into `~/Library/Fonts`
- Sources updated shell config

## Brewfile.local

Machine-specific packages (work tools, etc.) live in `Brewfile.local` (gitignored). `./install` installs it when present.

Shell: `HOMEBREW_BUNDLE_FILE_GLOBAL` points at `Brewfile`; use `bbi <formula>` / `bbic <cask>` to install and append (see `zsh/70-utils.zsh`).

`brew bundle cleanup --file Brewfile` only reads the main Brewfile, so local packages look orphaned. Use the wrapper instead:

```bash
./scripts/brew-bundle-cleanup.sh          # preview
./scripts/brew-bundle-cleanup.sh --force  # apply
```

## Removing Homebrew packages

Remove the item from `Brewfile` (or `Brewfile.local`), preview removals, then apply:

```bash
./scripts/brew-bundle-cleanup.sh
./scripts/brew-bundle-cleanup.sh --force
```

## macOS-specific setup

`scripts/macosx.sh` is **skipped by default**. It applies macOS defaults, login items, iTerm prefs, disables brew analytics, and restarts Dock/Finder/iTerm2.

To run it:

```bash
./install --with-macosx
```

Without the flag, install prints a warning and skips those changes.

## Runtimes (mise)

Node, Python, Go, and [Tuist](https://tuist.dev/en/docs/guides/install-tuist) are managed with [mise](https://mise.jdx.dev/). Global defaults live in `config/mise/config.toml` (symlinked to `~/.config/mise/config.toml`). Project repos can keep `.nvmrc`, `.python-version`, and `.go-version` unchanged; iOS repos can pin Tuist in `.mise.toml` or `mise.toml`.

## Shell history (Atuin)

After `./install`, run `atuin import auto` once if you want old `~/.zsh_history` in the database.

