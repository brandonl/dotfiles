eval "$(starship init zsh)"

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
if [[ -f "$DOTFILES/Brewfile" ]]; then
  export HOMEBREW_BUNDLE_FILE_GLOBAL="$DOTFILES/Brewfile"
  export HOMEBREW_BUNDLE_DESCRIBE=1
fi

export EDITOR=vim
export VISUAL="$EDITOR"
# Syntax-highlighted man pages via bat (theme from config/bat/config).
(( $+commands[bat] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT="-c"

export DOCKER_COMPOSE_RANDOM_SERVICE_PORT=0
export DOCKER_DEFAULT_PLATFORM=linux/amd64
export GOPATH="$HOME/workspace/go"
export SSH_KEY_PATH="~/.ssh/rsa_id"
export ZSH="$HOME/.zsh/omz"
export ZSH_COMPDUMP=$HOME/.cache/.zcompdump-$HOST
