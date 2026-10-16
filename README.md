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
- Installs Homebrew APM and global Claude/Codex configuration from `apm/global/apm.yml`
- Merges portable Codex preferences and installs RTK's native Codex hook
- Symlinks dotfiles into `$HOME` (`~/.zshrc`, `~/.config/*`, `~/.ssh/*`, git config, etc.)
- Links Orca's portable keybindings to `~/.orca/keybindings.json`
- Installs fonts into `~/Library/Fonts`
- Sources updated shell config

## Orca configuration

`config/orca/keybindings.json` links to Orca's supported
`~/.orca/keybindings.json`. `config/orca/settings.json` holds portable app
preferences. `./install` merges those preferences into Orca's local profile
after each install. A filtered allowlist shares user preferences; credentials,
publishing grants, work-specific prompts, machine paths, and repo/workspace
records stay local.

After changing Orca settings, capture them into this repo:

```bash
mise exec -- python ./scripts/orca-config-sync.py capture
```

Orca must be closed before preferences can be applied. If `./install` finds it
open, quit Orca and run:

```bash
mise exec -- python ./scripts/orca-config-sync.py apply
```

On a new Mac, launch Orca once, quit, then run `./install`.

Orca has no native standalone settings overlay yet, so the helper merges only
the allowlisted preferences into Orca's profile state
([upstream request](https://github.com/stablyai/orca/issues/21767)). It leaves
machine-specific and account state intact.

## Vorssaint configuration

[Vorssaint Settings.plist](config/vorssaint/Vorssaint%20Settings.plist) is a
native settings backup for manual transfer between Macs. In Vorssaint, use
**Settings → Advanced → Export settings…** to update it, then commit the file.
On another Mac, pull the change and use **Settings → Advanced → Import
settings…**. Import replaces Vorssaint's settings and relaunches the app.

The tracked backup omits audio device identifiers, device names, and fan curves.
Review future exports before replacing it; Vorssaint's exporter includes those
machine-specific values. Clipboard history, Scratchpad notes, Shelf items,
and system permissions are excluded by the app.

## Agent configuration

Public, machine-wide Claude and Codex dependencies live in
`apm/global/apm.yml`. `./install` installs the committed lockfile exactly.
Machine- or work-specific dependencies belong in ignored
`apm/global/apm.local.yml`. When present, installation merges it with the
public manifest and uses ignored `apm/global/apm.local.lock.yaml` for the
combined dependency graph.
APM is installed and upgraded through Homebrew; `scripts/apm-install.sh` uses
the Homebrew binary directly so an older standalone binary cannot shadow it.
Shared global instructions live in the tracked local packages under
`apm/global/packages/`; APM compiles them into `~/.codex/AGENTS.md` and
`~/.claude/CLAUDE.md`.
APM installs skills under `~/.agents/skills/` for Codex/Cursor and
`~/.claude/skills/` for Claude Code. Claude does not discover the shared
`.agents` path, so both targets are intentional and do not double-load a skill
within one client.
Portable personal skills live in the tracked `apm/global/plugins/personal/`
plugin. Machine- or work-specific personal skills live in the ignored
`apm/global/plugins/personal.local/` plugin, alongside `apm.local.yml`.
The public manifest references the tracked plugin, and `apm.local.yml`
references the local plugin. APM installs both from `~/dotfiles` with the
locked dependencies. Each plugin needs a `plugin.json` and
`skills/<name>/SKILL.md`.
Codex metadata overrides live under `apm/global/overrides/<skill>/agents/openai.yaml`.
The installer merges them after every APM install, preserving upstream UI metadata.
The five writing/comment skills use `policy.allow_implicit_invocation: false`
for explicit invocation only in Codex.
ELI5 uses the same Codex policy, plus the Claude Code
`skillOverrides.eli5: user-invocable-only` setting from
`apm/global/claude-skill-overrides.json`. Invoke it as `$eli5` in Codex or
`/eli5` in Claude Code.
Codex MCPs are installed with the Codex CLI, not APM, so APM never rewrites
`~/.codex/config.toml`.
`config/codex/preferences.toml` holds shared Codex preferences. The installer
merges them into `~/.codex/config.toml` with a pinned `tomlkit` script run by
`uv`. It runs `rtk init -g --codex` if the native hook is missing. Restart Codex
after installation, then review and trust the hook with `/hooks`. Credentials,
sessions, project trust, hook trust records,
marketplaces, plugin state, and machine-specific MCP commands stay local.
RTK creates `~/.codex/RTK.md`; APM owns `~/.codex/AGENTS.md`.
Reusable project dependency packages live under `apm/packages/`. A consuming
project references the package from its own `apm.yml`, resolves the transitive
dependencies, and commits its own lockfile. For example:

```yaml
dependencies:
  apm:
    - git: brandonl/dotfiles
      path: apm/packages/react-typescript
  mcp:
    - microsoft/playwright-mcp
```

Available packages:

- `apm/packages/go`
- `apm/packages/postgres`
- `apm/packages/react-typescript`
- `apm/packages/browser-extension` (includes `react-typescript`)

The packages intentionally omit lockfiles. Project MCP dependencies remain in
the consuming manifest so their trust boundary is explicit. Browser-extension
projects should declare both `io.github.ChromeDevTools/chrome-devtools-mcp` and
`microsoft/playwright-mcp` there.

To update a dependency:

```bash
# Edit the dependency ref in apm/global/apm.yml, then:
./scripts/apm-install.sh --update
git diff -- apm/global/apm.yml apm/global/apm.lock.yaml
```

For local dependencies, edit `apm/global/apm.local.yml` and run the same update
command. Its combined lockfile remains local and ignored.

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

## Neovim (LazyVim)

`config/nvim` is linked as a directory so `lazy-lock.json` stays trackable. First `nvim` launch bootstraps LazyVim and its plugins. The terminal owns TUI font and size; iTerm uses Monaco Nerd Font at 16 pt to match Zed's terminal size. LazyVim uses One Dark Pro colors and language extras for Ansible, Docker, Go, JSON, Markdown, Python, Terraform, TOML, and YAML.

## Shell history (Atuin)

After `./install`, run `atuin import auto` once if you want old `~/.zsh_history` in the database.

## Validation

Verify Dotbot links against an isolated temporary home without running package,
APM, mise, or macOS setup:

```bash
./tests/clean-install.sh
```
