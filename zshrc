eval "$(starship init zsh)"

export ZSH="$HOME/.zsh/omz"
export SSH_KEY_PATH="~/.ssh/rsa_id"
export GOPATH="$HOME/workspace/go"

path+=("/opt/homebrew/bin")
path+=("$HOME/bin")
path+=("/usr/local/bin")
path+=("$GOPATH/bin")
path+=("/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/")
path+=("/Users/brandon/Library/Application Support/JetBrains/Toolbox/scripts")
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

source '/opt/homebrew/opt/autoenv/activate.sh'
source $ZSH/oh-my-zsh.sh
source $HOME/.zsh/utils.zsh
[ -f $HOME/.zsh/local.zsh ] && source $HOME/.zsh/local.zsh

# https://github.com/marlonrichert/zsh-autocomplete?tab=readme-ov-file#reassign-tab
# Make Tab and ShiftTab cycle completions on the command line
# bindkey '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# Make Tab go straight to the menu and cycle there
bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# Move zcompdump spam (for auotcomplete) to .cache
export ZSH_COMPDUMP=$HOME/.cache/.zcompdump-$HOST
