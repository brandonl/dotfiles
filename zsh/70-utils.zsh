# ── GIT ────────────────────────────────────────────

# unalias ohmyzsh git plugin aliases
unalias gma
unalias gca
unalias gc
unalias gl

function gs() { git status $*; }
function gc() { git commit -m "$1"; }
function gca() { git commit --amend -C HEAD; }
function gl() { git dag --max-count=35 $*; }
function gma() { gcm && git pull $@; }
alias gpl="git pull"
(( $+commands[lazygit] )) && alias lg=lazygit
alias gds="git -c delta.side-by-side=true diff" # one-off side-by-side diff
alias gmaint="git maintenance start" # enable background gc/prefetch in current repo

function gco() {
  local branch
  branch=$(
    git for-each-ref --format='%(refname:short)' --sort=-committerdate refs/heads refs/remotes/origin |
      awk '$0 != "origin/HEAD" { sub(/^origin\//, ""); print }' |
      sort -u |
      fzf --preview 'git log --oneline --decorate --graph --max-count=30 {} 2>/dev/null || git log --oneline --decorate --graph --max-count=30 origin/{} 2>/dev/null'
  ) || return
  [[ -n "$branch" ]] && git checkout "$branch"
}

function gbd() {
  local current branches
  current=$(git branch --show-current)
  branches=("${(@f)$(
    git branch --format='%(refname:short)' --sort=-committerdate |
      awk -v current="$current" '$0 != current { print }' |
      fzf --multi --preview 'git log --oneline --decorate --graph --max-count=30 {}'
  )}")
  (( $#branches )) && git branch -d -- "${branches[@]}"
}

function gwd() {
  local current worktrees worktree
  current=$(git rev-parse --show-toplevel)
  worktrees=("${(@f)$(
    git worktree list --porcelain |
      awk '/^worktree / { sub(/^worktree /, ""); print }' |
      awk -v current="$current" '$0 != current { print }' |
      fzf --multi --preview 'git -C {} status --short --branch'
  )}")
  for worktree in "${worktrees[@]}"; do
    git worktree remove "$worktree"
  done
}


# ── AWS ────────────────────────────────────────────────
# fzf-pick an SSO profile, refresh the SSO token only if expired, then export
# temp creds into the shell. All profiles share the `ltk` sso-session, so one
# login covers every profile. Replaces awsume + fzf for this config.
function awsx() {
  local profile
  profile="${1:-$(aws configure list-profiles | fzf --prompt='aws> ' \
    --preview 'aws configure get sso_account_id --profile {}; aws configure get sso_role_name --profile {}')}"
  [[ -z "$profile" ]] && return 1

  if ! aws sts get-caller-identity --profile "$profile" &>/dev/null; then
    aws sso login --profile "$profile" || return 1
  fi

  eval "$(aws configure export-credentials --profile "$profile" --format env)"
  export AWS_PROFILE="$profile"
  aws sts get-caller-identity --output json
}
# drop exported creds + profile from the shell
function awsoff() { unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION; }

# ── DOCKER ────────────────────────────────────────────
# docker / docker-compose OMZ plugins: aliases + completions

(( $+commands[lazydocker] )) && alias lzd=lazydocker
function dstats() { docker stats $(docker ps -q); }
function dcsh() {
  containers=($(docker ps | awk '{if(NR>1) print $NF}'))
  select c in "${containers[@]}"; do
    docker exec -it $c bash
    break
  done;
}

# ── HOMEBREW BUNDLE ────────────────────────────────────
# Uses HOMEBREW_BUNDLE_FILE_GLOBAL ($DOTFILES/Brewfile) from 00-init.zsh

bbi() { brew bundle add --install --describe --global "$@"; }
bbic() { brew bundle add --install --describe --global --cask "$@"; }

# ── GENERAL ────────────────────────────────────────────

alias cat="bat --paging=never"
alias disk="duf"
alias examples="tldr"
alias less="bat --paging=always"
alias pss="procs"
alias sls=serverless
alias space="dust"

(( $+commands[glow] )) && alias md='glow'
(( $+commands[lnav] )) && alias logs=lnav
(( $+commands[btop] )) && alias top=btop
(( $+commands[jless] )) && alias json=jless
(( $+commands[glow] )) && alias -s md=glow
(( $+commands[jless] )) && alias -s json=jless yaml=jless yml=jless

reload() { exec zsh -l; }
alias work="cd $HOME/workspace"
alias "?"=which
alias m=make
alias l="eza -lha --icons=auto --group-directories-first --git"

# ── NAV ────────────────────────────────────────────────
alias ..="cd .."                       # OMZ only aliases ...,....,etc
mkcd() { mkdir -p "$1" && cd "$1"; }    # make dir + cd into it
