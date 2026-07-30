# Plan: agent config sync via APM (Agent Package Manager)

Goal: stop hand-copying Claude/Codex skills, plugins, agents, MCP servers between
machines. Use [microsoft/apm](https://github.com/microsoft/apm) as the dependency
layer, same role `Brewfile` plays for packages. Three scopes: global (all
machines), work (work machine only, private sources), project (lives in the
project's own repo, not here).

Not yet installed/tested against the real CLI in this repo — treat CLI flags
below as sourced from APM docs (v0.3 manifest, CLI reference, 2026-05-20), not
verified locally. Confirm during step 1 of rollout.

## Why APM over the alternatives considered

- One manifest covers skills + agents + hooks + prompts + MCP servers, across
  Claude Code, Codex, Copilot, Cursor, Gemini, Windsurf, etc. `skills.sh` only
  covers skills.
- `apm install -g` deploys to user scope (`~/.apm/`, then compiled out to
  `~/.claude/`, `~/.codex/`, etc.) instead of per-project — matches "global,
  synced across machines" requirement.
- Lockfile (`apm.lock.yaml`) + content-hash pinning + hidden-unicode scan on
  install — reasonable to commit and trust, unlike hand-copied skill text.
- Private/internal sources supported natively via git host auth
  (`GITHUB_APM_PAT` / `GITLAB_APM_PAT` / `ADO_APM_PAT`), so work-only skills
  never need their text checked into a personal repo.

## Directory layout (new, in this repo)

```
apm/
  global/
    apm.yml          # committed — public/personal deps, all machines
    apm.lock.yaml     # committed — resolved+pinned tree
  work/
    apm.yml          # committed — points at private work sources by URL only
    apm.lock.yaml     # committed
scripts/
  apm-install.sh      # new — runs the two installs below
```

`apm/work/apm.yml` contains no proprietary text, just dependency pointers
(`git:` URLs / registry refs) to the work org's private skill sources —
identical in spirit to `.gitmodules` already doing this for zsh plugins.

## Scoping model

- **Global** (`apm/global/apm.yml`): personal + community skills/plugins/MCP
  servers you want on every machine. Installed with `apm install -g` from
  inside `apm/global/`, so output lands in user scope, not this repo.
- **Work** (`apm/work/apm.yml`): work-internal skills. Same `-g` global
  install, but gated behind an env var the same way `scripts/macosx.sh` is
  gated behind `DOTFILES_WITH_MACOSX` — e.g. `DOTFILES_WITH_WORK=1`. Only runs
  on the work machine. Needs a `GITHUB_APM_PAT` (or org equivalent) present in
  the environment — sourced from wherever secrets already live on that
  machine (1Password CLI, etc.), never committed.
- **Project-specific**: out of scope for dotfiles entirely. Each project gets
  its own `apm.yml` at its own repo root, per APM's normal per-project usage.
  Nothing to build here — just don't let global skills leak into project
  manifests.

## Install wiring

New `scripts/apm-install.sh`:

```bash
#!/usr/bin/env bash
set -e

command -v apm >/dev/null || curl -sSL https://aka.ms/apm-unix | sh

(cd apm/global && apm install -g --frozen)

if [[ "${DOTFILES_WITH_WORK:-0}" == "1" ]]; then
  (cd apm/work && apm install -g --frozen)
fi

apm compile --global
```

`install.conf.yaml` shell section gets one line added, alongside the existing
`git submodule` steps:

```yaml
- shell:
    - [./scripts/apm-install.sh, "Install and sync agent skills/plugins via APM"]
```

`--frozen` = install exactly what's in the lockfile, no re-resolution — same
intent as committing `Brewfile.lock`-style reproducibility.

## Lockfile handling

Commit both `apm/global/apm.lock.yaml` and `apm/work/apm.lock.yaml`. Adding or
bumping a dependency happens by hand (`apm install <dep>` inside the relevant
dir, no `--frozen`), then commit the manifest + lockfile diff together —
mirrors how Brewfile changes are committed today.

## Migration of what's already in place

`caveman` is currently a Claude Code plugin installed directly (marketplace
add), not APM-managed. Fold it into `apm/global/apm.yml` as a normal
dependency pointing at its existing source, so it's reproducible from a fresh
machine instead of a manual `claude plugin marketplace add`. Do this once APM
is confirmed working, not as part of initial rollout (avoid breaking a working
setup while validating a new tool).

## Open questions to resolve during rollout (not assumptions to build on)

1. Confirm `apm install -g` reads `apm.yml` from cwd and only redirects the
   *output* to `~/.apm/` (this is the working assumption; verify against
   `apm --help install` on first real run).
2. Confirm `apm compile --global` correctly renders both Claude's and Codex's
   root-context files from one call, or whether per-target `--target` compile
   is needed.
3. Confirm work-machine auth story for `GITHUB_APM_PAT` — where it's sourced
   from on that machine, so `scripts/apm-install.sh` doesn't need to know.
4. Decide whether `apm audit` should be wired into `scripts/doctor.sh` as a
   periodic check.

## Rollout steps

1. Install APM locally, hand-run `apm install -g` against a throwaway
   `apm.yml` with one known-good public skill, confirm it lands in
   `~/.claude/` / `~/.codex/` as expected.
2. Create `apm/global/apm.yml` with current public/personal deps (start with
   `caveman` migration).
3. Write `scripts/apm-install.sh`, wire into `install.conf.yaml`.
4. Run full `./install` on this machine, verify no regressions to existing
   Claude Code setup.
5. On work machine: create `apm/work/apm.yml`, set `DOTFILES_WITH_WORK=1` in
   shell env (not in this repo), confirm private deps resolve.
6. Commit lockfiles, document the two env vars (`DOTFILES_WITH_WORK`,
   `GITHUB_APM_PAT`) in README.
