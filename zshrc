# Load ~/.zsh/NN-name.zsh in numeric order (omz/ is the OMZ install tree, not sourced here).
ZSH_DIR=${ZDOTDIR:-$HOME}/.zsh

for config in $ZSH_DIR/[0-9][0-9]-*.zsh(Nn); do
  source $config
done
