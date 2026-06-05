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


# ── DOCKER ────────────────────────────────────────────
# docker / docker-compose OMZ plugins: aliases + completions

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

reload() { exec zsh -l; }
alias work="cd $HOME/workspace"
alias "?"=which
alias m=make
alias l="eza -lha --icons=auto --group-directories-first --git"
