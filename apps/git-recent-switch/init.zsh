# git-recent-switch init: source to enable the portable plugin.
# Usage: source /path/to/apps/git-recent-switch/init.zsh
# Example: source "$HOME/.zsh/plugins/git-recent-switch/init.zsh"

[[ -n ${_GRS_PLUGIN_LOADED-} ]] && return
typeset -g _GRS_PLUGIN_LOADED=1

typeset -gU fpath
typeset _grs_root="${0:A:h}"
fpath=( "${_grs_root}/functions" "${_grs_root}/completions" ${fpath} )

autoload -Uz git-recent-switch

if [[ $- == *i* ]]; then
  if ! typeset -f compinit >/dev/null; then
    autoload -Uz compinit
  fi
  : ${ZSH_COMPDUMP:=${HOME:-${_grs_root}}/.zsh/.zcompdump}
  mkdir -p "${ZSH_COMPDUMP:h}" 2>/dev/null || true
  if [[ -z ${_GRS_COMPINIT_DONE-} ]]; then
    compinit -d "${ZSH_COMPDUMP}" 2>/dev/null || true
    typeset -g _GRS_COMPINIT_DONE=1
  fi

  alias grs='git-recent-switch'
fi
