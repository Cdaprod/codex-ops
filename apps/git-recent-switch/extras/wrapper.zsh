# git-recent-switch wrapper: intercepts `git switch` without arguments.
# Usage: source /path/to/extras/wrapper.zsh
# Example: source "$HOME/.zsh/plugins/git-recent-switch/extras/wrapper.zsh"

[[ -n ${_GRS_WRAPPER_LOADED-} ]] && return
typeset -g _GRS_WRAPPER_LOADED=1

if command -v git >/dev/null 2>&1; then
  if ! typeset -f _grs_original_git >/dev/null; then
    _grs_original_git() { command git "$@"; }
  fi

  git() {
    if [[ "$1" == switch && -z "${2-}" ]]; then
      git-recent-switch
    else
      _grs_original_git "$@"
    fi
  }
fi
