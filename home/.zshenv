# ~/.zshenv — read by every zsh, so it stays tiny.
#
# A terminal window starts a non-login shell that already carries the session's environment.
# Fedora's /etc/zshrc would still re-run every script in /etc/profile.d for it: about 150 ms per
# new terminal, most of it one `flatpak` call. That file is skipped when the environment shows
# the login scripts have already run (LESSOPEN is one of the things they set); ~/.zshrc takes
# care of the few per-terminal settings itself. Login shells, and shells started with a bare
# environment, read the system files as usual.
[[ -o login || -z $LESSOPEN ]] || unsetopt GLOBAL_RCS
