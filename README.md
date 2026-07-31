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
- Installs global Claude/Codex configuration from `apm/global/apm.yml`
- Symlinks dotfiles into `$HOME` (`~/.zshrc`, `~/.config/*`, `~/.ssh/*`, git config, etc.)
- Installs fonts into `~/Library/Fonts`
- Sources updated shell config

## Agent configuration

Public, machine-wide Claude and Codex dependencies live in
`apm/global/apm.yml`. `./install` installs the committed lockfile exactly.
APM installs skills under `~/.agents/skills/` for Codex/Cursor and
`~/.claude/skills/` for Claude Code. Claude does not discover the shared
`.agents` path, so both targets are intentional and do not double-load a skill
within one client.
Codex MCPs are installed with the Codex CLI, not APM, so APM never rewrites
`~/.codex/config.toml`.
Project starter manifests live in `apm/templates/`; they intentionally omit
lockfiles so each consuming project resolves and commits its own.

To update a dependency:

```bash
# Edit the dependency ref in apm/global/apm.yml, then:
./scripts/apm-install.sh --update
git diff -- apm/global/apm.yml apm/global/apm.lock.yaml
```

Work-specific agent configuration stays local to the work machine and is not
managed by this repo.

## Brewfile.local

Machine-specific packages (work tools, etc.) live in `Brewfile.local` (gitignored). `./install` installs it when present.

Shell: `HOMEBREW_BUNDLE_FILE_GLOBAL` points at `Brewfile`; use `bbi <formula>` / `bbic <cask>` to install and append (see `zsh/70-utils.zsh`).

`brew bundle cleanup --file Brewfile` only reads the main Brewfile, so local packages look orphaned. Use the wrapper instead:

```bash
brew-bundle-cleanup          # preview (on PATH via $DOTFILES/bin)
brew-bundle-cleanup --force  # apply
```

User-facing commands live in `bin/` (on PATH). Install-only scripts stay in `scripts/`.

## Removing Homebrew packages

Remove the item from `Brewfile` (or `Brewfile.local`), preview removals, then apply:

```bash
brew-bundle-cleanup
brew-bundle-cleanup --force
```

## macOS-specific setup

`scripts/macosx.sh` is **skipped by default**. It enables and verifies Touch ID for `sudo`, applies macOS defaults, login items, iTerm prefs, disables brew analytics, and restarts affected apps.

To run it:

```bash
./install --with-macosx
```

First run may require the account password to install `/etc/pam.d/sudo_local`.
The script then clears sudo's credential cache and asks again, verifying Touch ID
works on that Mac.

To repair only Touch ID sudo:

```bash
./scripts/sudo-touchid.sh
```

Touch ID is verified after a repair. Force another verification with
`SUDO_TOUCHID_VERIFY=1 ./scripts/sudo-touchid.sh`.

Without the flag, install prints a warning and skips those changes.

## Runtimes (mise)

Node, Python, Go, and [Tuist](https://tuist.dev/en/docs/guides/install-tuist) are managed with [mise](https://mise.jdx.dev/). Global defaults live in `config/mise/config.toml` (symlinked to `~/.config/mise/config.toml`). Project repos can keep `.nvmrc`, `.python-version`, and `.go-version` unchanged; iOS repos can pin Tuist in `.mise.toml` or `mise.toml`.

## Shell history (Atuin)

After `./install`, run `atuin import auto` once if you want old `~/.zsh_history` in the database.
