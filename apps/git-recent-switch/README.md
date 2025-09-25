# git-recent-switch

`git-recent-switch` is a portable Zsh plugin that adds an interactive picker for `git switch` when no
branch argument is provided. It prefers [`fzf`](https://github.com/junegunn/fzf) when available and falls
back to a numbered TTY menu, making it usable across minimal environments.

## Layout

```
apps/git-recent-switch/
├── README.md
├── init.zsh
├── git-recent-switch.plugin.zsh
├── completions/
│   └── _git-recent-switch
├── functions/
│   └── git-recent-switch
└── extras/
    ├── keybind.zsh
    └── wrapper.zsh
```

## Installation

### Automated install (recommended)

Run the installer script to copy the plugin into a user-scoped plugin directory.

```bash
python apps/git-recent-switch/install.py --dest "$HOME/.zsh/plugins"
```

The script is idempotent, so re-running it keeps the plugin up to date. Afterwards,
source `init.zsh` (and any extras) from that location.

```zsh
# ~/.zshrc (after compinit)
source "$HOME/.zsh/plugins/git-recent-switch/init.zsh"
source "$HOME/.zsh/plugins/git-recent-switch/extras/wrapper.zsh"   # optional
source "$HOME/.zsh/plugins/git-recent-switch/extras/keybind.zsh"   # optional
```

### Manual install

Plain Zsh:

```zsh
# ~/.zshrc (after compinit)
source ${0:h}/../apps/git-recent-switch/init.zsh
# optional extras
source ${0:h}/../apps/git-recent-switch/extras/wrapper.zsh
source ${0:h}/../apps/git-recent-switch/extras/keybind.zsh
```

Oh-My-Zsh:

```zsh
ln -s "$PWD/apps/git-recent-switch" "$HOME/.oh-my-zsh/custom/plugins/git-recent-switch"
plugins+=(git-recent-switch)
```

## Usage

- Run `git-recent-switch` inside a Git repository to open the picker.
- With the optional wrapper loaded, `git switch` (no args) opens the picker automatically.
- The keybind extra maps `Ctrl+G` followed by `s` to trigger the picker via ZLE.

## Tests

Execute from the repository root:

```bash
pytest tests/test_git_recent_switch.py
```

The test suite bootstraps a temporary Git repository and asserts that the menu fallback correctly
switches branches without `fzf` installed.
