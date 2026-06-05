export SHOW_AWS_PROMPT=false

zstyle ':omz:plugins:eza' dirs-first yes
zstyle ':omz:plugins:eza' git-status yes

plugins=(
  # almostontop # pins prompt to top; hides scrollback — off
  aws
  brew
  direnv # https://direnv.net/
  docker
  docker-compose
  eza # https://github.com/eza-community/eza
  extract # archive extraction helper
  gh
  git
  git-trim # https://github.com/jasonmccreary/git-trim
  mise # https://mise.jdx.dev/ (node/python/go via idiomatic version files)
  sudo # press Esc twice to prepend sudo
  you-should-use # https://github.com/MichaelAquilina/zsh-you-should-use
  zoxide # https://github.com/ajeetdsouza/zoxide
  # zsh-autocomplete off: ↑ bound to atuin-up-search; re-enable only with `atuin init zsh --disable-up-arrow`
  # zsh-autocomplete # https://github.com/marlonrichert/zsh-autocomplete
  zsh-dircolors-solarized # https://github.com/joel-porquet/zsh-dircolors-solarized
  zsh-defer # https://github.com/romkatv/zsh-defer
)

# zsh-completions keeps completions under src/, so add it before OMZ runs compinit.
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
fpath=("$ZSH_CUSTOM/plugins/zsh-completions/src" $fpath)

# fzf key bindings/completion need a TTY; skip in scripts/non-interactive shells
[[ -t 0 ]] && plugins+=(fzf) # https://github.com/junegunn/fzf
[[ -t 0 ]] && plugins+=(fzf-tab) # https://github.com/Aloxaf/fzf-tab

# Draws gray ghost text at end of line (Atuin does not — it only supplies matches; see defer below)
plugins+=(zsh-autosuggestions) # load after fzf-tab
plugins+=(zsh-syntax-highlighting) # load last

source $ZSH/oh-my-zsh.sh

# Atuin (deferred = load after OMZ so startup stays fast):
#   • Saves each command to its SQLite DB (preexec/precmd)
#   • Ctrl+R / ↑ → full-screen search UI
#   • Registers strategy "atuin" so zsh-autosuggestions queries that DB for ghost text
zsh-defer -c '(( $+commands[atuin] )) && { eval "$(atuin init zsh --disable-ai)"; ZSH_AUTOSUGGEST_STRATEGY=(atuin); }'

# Tab: accept atuin-backed ghost suggestion, else normal completion
_autosuggest_or_complete() {
  emulate -L zsh
  if (( $#POSTDISPLAY )) && (( CURSOR == $#BUFFER )); then
    zle autosuggest-accept
  else
    zle expand-or-complete
  fi
}
zle -N _autosuggest_or_complete
bindkey '^I' _autosuggest_or_complete

# ── FZF ────────────────────────────────────────────────
# Use fd as the source (respects .gitignore, shows hidden) when available.
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .next --exclude dist --exclude build --exclude Library'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .next --exclude dist --exclude build --exclude Library'
fi

# Catppuccin Mocha theme + sane layout (matches starship palette).
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --multi \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a"

# Previews for the built-in CTRL-T (files) and ALT-C (dirs) widgets.
(( $+commands[bat] )) && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
(( $+commands[eza] )) && export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=auto {}'"

# fzf-tab: follow FZF_DEFAULT_OPTS + show previews during tab completion.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=2 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:(ssh|scp|sftp):*' fzf-preview 'dig +short $word 2>/dev/null'
