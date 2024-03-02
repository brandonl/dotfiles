# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

eval "$(starship init zsh)"

export ZSH="/Users/brandon/.oh-my-zsh"
export SSH_KEY_PATH="~/.ssh/rsa_id"
export GOPATH="$HOME/workspace/go"

path+=("/opt/homebrew/bin")
path+=("$HOME/bin")
path+=("/usr/local/bin")
path+=("$GOPATH/bin")
path+=("/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/")
export PATH

# ZSH_THEME="spartan"
# ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  alias-tips # https://github.com/djui/alias-tips
  almostontop
  autoenv
  aws
  git
  git-trim # https://github.com/jasonmccreary/git-trim
  k # https://github.com/supercrabtree/k
  thefuck # hit esc esc or type fuck
  you-should-use
  zsh-autocomplete
  zsh-dircolors-solarized
  zsh-lsd  # https://github.com/z-shell/zsh-lsd
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
source $HOME/.utils.zsh
source $HOME/.local.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# https://github.com/marlonrichert/zsh-autocomplete?tab=readme-ov-file#reassign-tab
# Make Tab and ShiftTab cycle completions on the command line
# bindkey '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# Make Tab go straight to the menu and cycle there
bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete
