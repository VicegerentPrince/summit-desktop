"""Tab titles for kitty, used through {custom} in tab_title_template (see kitty.conf).

A tab shows an icon for the program in its foreground and the folder it is in; when that program
is not a shell, its title (normally the command line) follows. Icons are Nerd Font glyphs, written
as escapes so that this file survives any editor.
"""
import os

_ICONS = (
    ('zsh bash fish sh',                        '\uf07c'),        # folder: a shell waiting for a command
    ('nvim',                                    '\ue6ae'),        # neovim
    ('vim vi',                                  '\ue62b'),        # vim
    ('nano micro',                              '\U000f03eb'),    # pencil
    ('node npm pnpm npx bun deno yarn',         '\U000f0399'),    # node
    ('python python3 ipython uv pip',           '\ue73c'),        # python
    ('go',                                      '\ue627'),        # go
    ('cargo rustc',                             '\ue7a8'),        # rust
    ('git lazygit delta',                       '\ue702'),        # git
    ('gh',                                      '\uf09b'),        # github
    ('docker lazydocker podman',                '\uf308'),        # docker
    ('ssh kitten mosh',                         '\U000f048d'),    # server
    ('claude',                                  '\U000f06a9'),    # robot
    ('btop htop top',                           '\U000f012a'),    # chart
    ('yazi',                                    '\U000f0968'),    # folder search
    ('man less bat',                            '\uf02d'),        # book
    ('sudo',                                    '\U000f0483'),    # shield
    ('dnf flatpak rpm',                         '\U000f03d6'),    # package
    ('tmux',                                    '\uebc8'),        # tmux
    ('psql sqlite3 mysql',                      '\uf1c0'),        # database
    ('make task just',                          '\uf013'),        # cog
)
ICONS = {name: glyph for names, glyph in _ICONS for name in names.split()}
SHELLS = frozenset(_ICONS[0][0].split())
OTHER = '\uf120'          # a prompt sign, for anything not listed
HOME = os.path.expanduser('~')
LONGEST = 30               # characters of folder and command; keeps the pill's rounded end on screen


def draw_title(data):
    try:
        tab = data['tab']
        exe = tab.active_exe or ''
        wd = tab.active_wd or ''
        folder = '~' if wd == HOME else (wd.rstrip('/').rsplit('/', 1)[-1] or '/')
        icon = ICONS.get(exe, OTHER)
        label = folder if exe in SHELLS or not exe else f'{folder} \u203a {data.get("title") or exe}'
        if len(label) > LONGEST:
            label = label[:LONGEST - 1] + '\u2026'
        return f'{icon} {label}'
    except Exception:           # never let a title break the tab bar
        return str(data.get('title', ''))
