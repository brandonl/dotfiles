# Load ~/.zsh/NN-name.zsh in numeric order (omz/ is the OMZ install tree, not sourced here).
ZSH_DIR=${ZDOTDIR:-$HOME}/.zsh

if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zmodload zsh/zprof
fi

for config in $ZSH_DIR/[0-9][0-9]-*.zsh(Nn); do
  source $config
done

if [[ -n "${ZSH_PROFILE:-}" ]]; then
  zprof
fi
