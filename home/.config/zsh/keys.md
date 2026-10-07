# Keys and commands

## Terminal (kitty)

| Keys | Does |
|---|---|
| `Ctrl+Alt+T` or `Meta+Enter` | new terminal |
| `Ctrl+Shift+T` | new tab, same folder |
| `Ctrl+Shift+N` | new window, same folder |
| `Ctrl+Shift+Enter` | split, same folder (`Ctrl+Shift+\` side by side, `Ctrl+Shift+-` stacked) |
| `Ctrl+Alt+arrows` | move between splits |
| `Ctrl+Shift+M` | zoom the current split, and back |
| `Alt+1` … `Alt+9` | jump to a tab |
| `Ctrl+Shift+Z` / `X` | jump to the previous / next prompt |
| `Ctrl+Shift+G` | open the last command's output in a pager |
| `Ctrl+Shift+E` | open a link on screen with the keyboard |
| `Ctrl+Shift+/` | browse the scrollback |
| `Ctrl+Shift+A` then `1` / `D` | solid background / back to glass |
| `Ctrl+Shift+F5` | reload the kitty config |

## Shell

| Keys | Does |
|---|---|
| `Tab` | completion in a fuzzy menu with previews (`<` `>` switch group) |
| `→` or `Ctrl+Space` | accept the grey suggestion |
| `↑` / `↓` | history, filtered by what is already typed |
| `Ctrl+R` | search all history; `Ctrl+R` again narrows to this project, this folder, this terminal |
| `Ctrl+T` / `Alt+C` | pick a file / go to a folder, fuzzy |
| `Alt+P` | jump to a project in ~/Documents/Projects |
| `Esc Esc` | put `sudo` in front of the command |
| `Ctrl+X Ctrl+E` | edit the command in the editor |
| `Ctrl+Backspace` | delete a word |

## Commands

| Command | Does |
|---|---|
| `cd name` | jumps to the folder you use most that matches; `cdi` to choose |
| `ll`, `la`, `lt` | long list, with hidden files, tree |
| `y` | file manager (quit with `q` to stay in the folder you browsed to) |
| `lg`, `lzd` | git and docker in a full-screen view |
| `cat file` | with syntax colours; `man` pages are coloured too |
| `git diff`, `git show`, `git log -p` | syntax-coloured diffs; `n` / `N` jump between files, `git -c delta.features=side diff` for side by side |
| `btop` | what the machine is doing |
| `tldr tool` | short examples for a command |
| `dust`, `duf` | what uses the disk, by folder / by drive |
| `glow file.md` | read Markdown |
| `wall next`, `wall random`, `wall fetch` | wallpapers from the terminal |
| `mkcd dir` | make a folder and enter it |
| `update` | system, Flatpak apps and CLI tools |
| `1`, `2`, `3` | jump to the projects listed on the welcome card |
| `welcome` | show the welcome card again (`welcome off` / `welcome on` to hide or restore it) |
| `keys` | this page |

## Editor (nano)

| Keys | Does |
|---|---|
| `Ctrl+S`, `Ctrl+Q` | save, quit (`Ctrl+O` and `Ctrl+X` work as before) |
| `Ctrl+F` | find; `Alt+W` next match |
| `Ctrl+Z` / `Ctrl+Y` | undo / redo |
| `Ctrl+C` / `Ctrl+V` | copy / paste a line or the marked text (`Alt+A` starts marking, `Ctrl+K` cuts) |
