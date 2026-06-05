# Keep the next prompt near the middle / 2/3 of the viewport (scrollback preserved).
# PROMPT_ROW_PAD=0 disables. PROMPT_ROW_FRACTION=66 (default ≈ 2/3), 50 ≈ middle.

[[ "${PROMPT_ROW_PAD:-1}" == 0 ]] && return

typeset -gi PROMPT_ROW_FRACTION=${PROMPT_ROW_FRACTION:-66}
# Starship uses a 2-line prompt; target row is the line with ❯
typeset -gi PROMPT_MULTILINE=${PROMPT_MULTILINE:-2}

_prompt_position_target_row() {
  local -i target=$(( LINES * PROMPT_ROW_FRACTION / 100 ))
  (( PROMPT_MULTILINE > 1 )) && (( target -= PROMPT_MULTILINE - 1 ))
  (( target < 1 )) && target=1
  print -r -- $target
}

# DEC CPR: ESC [ row ; col R
_prompt_position_cursor_row() {
  local pos row
  [[ -r /dev/tty ]] || return 1
  exec {fd}<>/dev/tty
  print -rn $'\e[6n' >&$fd
  if ! read -rs -t 0.15 -d R pos <&$fd; then
    exec {fd}<&-
    return 1
  fi
  exec {fd}<&-
  if [[ $pos =~ '\[?([0-9]+);([0-9]+)' ]]; then
    row=$match[1]
  else
    pos=${pos#*$'\e['}
    row=${pos%%;*}
  fi
  [[ $row = <-> ]] || return 1
  print -r -- $row
}

_prompt_position_apply() {
  emulate -L zsh
  [[ -t 1 ]] || return
  (( LINES > 8 )) || return

  local -i target end pad up
  target=$(_prompt_position_target_row) || return
  end=$(_prompt_position_cursor_row) || return

  # Ghostty/iTerm often report row 1 in precmd while output is at the bottom.
  if (( end == 1 )); then
    end=$(( LINES - 1 ))
  elif (( end < 1 || end > LINES )); then
    return
  fi

  pad=$(( target - end ))

  # Reject absurd padding (bad CPR).
  if (( pad > LINES * 2 / 3 )); then
    return
  fi

  if (( pad > 0 )); then
    print -rn -- "${(pl:$pad::\n:)}"
  elif (( pad < -1 )); then
    up=$(( -pad ))
    (( up > LINES - 1 )) && up=$(( LINES - 1 ))
    printf '\e[%dS' $up >/dev/tty
  fi
}

_prompt_position_clear-widget() {
  emulate -L zsh
  _prompt_position_apply
  zle -I
  zle -R
}

zle -N clear-screen-soft-bottom _prompt_position_clear-widget
bindkey '^L' clear-screen-soft-bottom

clear() {
  if (( PROMPT_ROW_PAD )); then
    _prompt_position_apply
  else
    command clear "$@"
  fi
}

precmd_functions+=(_prompt_position_apply)
