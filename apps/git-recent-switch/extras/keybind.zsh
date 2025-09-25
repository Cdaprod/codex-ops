# git-recent-switch keybind: Ctrl+G then s triggers the picker via ZLE.
# Usage: source /path/to/extras/keybind.zsh
# Example: source "$HOME/.zsh/plugins/git-recent-switch/extras/keybind.zsh"

[[ $- == *i* ]] || return 0
[[ -n ${_GRS_KEYBIND_LOADED-} ]] && return
typeset -g _GRS_KEYBIND_LOADED=1

function git_recent_switch_widget() {
  zle -U "git switch"$'\n'
}
zle -N git_recent_switch_widget
bindkey -s '^Gs' 'git switch\n'
