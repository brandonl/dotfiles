# Once per day: compare Atuin history to config/tools/replacements.tsv.
[[ -o interactive ]] && [[ -t 0 && -t 1 ]] || return
zsh-defer -c '(( $+commands[tools] )) && tools --nudge'
