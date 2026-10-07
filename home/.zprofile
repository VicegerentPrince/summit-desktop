# ~/.zprofile — read once by a login zsh. After `chsh -s /usr/bin/zsh` that is the shell which
# builds the environment of the whole desktop session, so this keeps what ~/.bash_profile gives
# today: the personal bin folders and the mise-managed tools (node, pnpm, go, ...) on PATH for
# programs started from the desktop, not only for those started from a terminal.
typeset -U path
path=($HOME/.local/share/mise/shims $HOME/.local/bin $HOME/bin $path)
export EDITOR=nano
