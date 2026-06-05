# zsh options not already set by OMZ (auto_cd/auto_pushd/pushd_ignore_dups live in OMZ libs).

setopt EXTENDED_GLOB        # ^ ~ # qualifiers in globs
setopt GLOB_DOTS            # match dotfiles without leading .
setopt NUMERIC_GLOB_SORT    # sort numbered files numerically
setopt INTERACTIVE_COMMENTS # allow # comments at the prompt
setopt PUSHD_SILENT         # don't print dir stack on pushd/popd
setopt NO_BEEP              # stop the terminal bell
setopt NO_FLOW_CONTROL      # free up ^S / ^Q
