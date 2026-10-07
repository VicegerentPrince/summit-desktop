# KDE Store listings

Build the files with `store/build.sh` (they land in `dist/`). Images are in `store/images/`.
Licence **GPL-3.0** for every product except Summit Glass, which keeps Breeze's **LGPL**. Link each to https://github.com/VicegerentPrince/summit-desktop.

| # | Product | Category | File | Images |
|---|---|---|---|---|
| 1 | Summit Desktop | Various Plasma 6 Improvements | `summit-desktop-1.0.0.tar.gz` | summit-desktop.jpg, summit-terminal.png, glass-panel-before-after.png, wallpapers-gallery.png |
| 2 | Summit Vitals | Plasma 6 Monitoring | `summit-vitals-1.0.0.plasmoid` | vitals-card.png, widgets-on-desktop.jpg |
| 3 | Summit Claude Usage | Plasma 6 Monitoring | `summit-claude-usage-1.0.0.plasmoid` | claude-card.png, widgets-on-desktop.jpg |
| 4 | Summit Wallpapers | Plasma 6 Applets | `summit-wallpapers-1.0.0.plasmoid` | wallpapers-gallery.png, summit-desktop.jpg |
| 5 | Summit | KDE Color Scheme KDE4 | `Summit.colors` | colours-settings.png, summit-desktop.jpg |
| 6 | Summit Glass | Plasma Theme | `summit-glass-1.0.0.tar.gz` | glass-panel-before-after.png, summit-desktop.jpg |

Products 2 to 6 install from Plasma's own "Get New…" buttons. Product 1 is the complete setup,
downloaded and installed with its script.

---

## 1. Summit Desktop

**Summary:** A fast, glassy Plasma 6 desktop and terminal: Liquid Glass widgets, accent colours taken from your wallpaper, and a kitty + zsh setup that opens in 5 ms.

**Description:**

The complete Summit setup in one download: desktop, panel, widgets, terminal, shell, editor and tool themes. Everything installs for your user only (no root), can be re-run safely, and backs up anything it replaces.

Desktop
- Liquid Glass clock, calendar, weather and music widgets by Jack Faith (jaxparrow07), installed from his GitHub at a pinned version with fixes applied: the clock no longer redraws at 60 fps (23% of a CPU core down to under 1%), the music widget uses a quarter of the CPU and its play/pause works with phones through KDE Connect, and the glass no longer turns black after login.
- Three more cards in the same glass: Vitals (CPU, memory, disk, network, temperature, battery), Claude Usage (Claude Code plan limits) and a Wallpapers gallery for the panel with endless Wallhaven photos at your screen's resolution.
- The accent colour follows your wallpaper, picked in a perceptual colour space and checked for readable contrast (WCAG AA) in your colour scheme.
- Summit colour scheme, Summit Glass panel, Papirus icons with teal folders, Bibata cursor, Inter and JetBrains Mono.

Terminal
- kitty with a welcome card (your wallpaper, your three latest projects, a tip), tabs with program icons and rounded split panes.
- zsh with Powerlevel10k, fuzzy Tab completion with previews, atuin history, zoxide, autosuggestions and syntax highlighting, tuned so the prompt appears in about 5 ms and a typo answers instantly.
- Matching themes for bat, git diffs (delta), lazygit, yazi, btop, tmux, eza, nano, fzf, tldr, glow, Neovim, Kate, VS Code and Cursor.

Install: unpack, then run `./install.sh --layout` (see README.md for the one dnf line it needs on Fedora). Built and tested on Fedora 44 with Plasma 6.7 (Wayland); other distributions should work with their own package names.

Credits
- Liquid Glass widgets and the glass effect: Jack Faith (jaxparrow07), https://github.com/jaxparrow07/liquidglass-kde-widgets (GPL-3.0). His widgets are also on this store; support him at https://ko-fi.com/devrinth
- Wallpapers come from https://wallhaven.cc and belong to their photographers; none are included.
- Summit Glass is based on Breeze by the KDE Visual Design Group.

Source and issues: https://github.com/VicegerentPrince/summit-desktop

---

## 2. Summit Vitals

**Summary:** CPU, memory, free disk, network, temperature and battery on a Liquid Glass card.

**Description:**

A calm system card in the Liquid Glass style: CPU and memory use, free disk space, network speed, CPU temperature and battery, with thin bars that turn amber and red only when something needs attention. Reads Plasma's own system monitor service every two seconds and has no animations, so it stays light.

- Resizable; the layout scales with the card.
- Appearance settings for the glass (tint, blur, refraction, glass or solid, light or dark).
- Inter Display is included, so it looks the same on any system.

The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0 with credit: https://github.com/jaxparrow07/liquidglass-kde-widgets (his clock, calendar and weather widgets are on this store too). Part of Summit: https://github.com/VicegerentPrince/summit-desktop

---

## 3. Summit Claude Usage

**Summary:** Your Claude plan's 5-hour and weekly limits, as Claude Code reports them, on a Liquid Glass card. Unofficial.

**Description:**

Shows how much of your Claude plan's 5-hour window and weekly allowance you have used, and when each resets, with bars that turn amber at 70% and red at 90%.

How it gets the numbers: Claude Code passes its plan limits to its status line. The widget includes a status line script that shows model, folder, git branch, context and limits in Claude Code, and saves the two figures to ~/.cache/summit/claude-usage.json for the card. Nothing is fetched from the network and no credentials are read.

Setup: right-click the card › Configure › Setup, copy the snippet into ~/.claude/settings.json. Needs Claude Code and jq.

Not affiliated with or endorsed by Anthropic. The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. Part of Summit: https://github.com/VicegerentPrince/summit-desktop

---

## 4. Summit Wallpapers

**Summary:** A wallpaper gallery for the panel: your library plus endless top-rated Wallhaven photos at your screen's resolution.

**Description:**

Click the panel icon for a gallery of ~/Pictures/Wallpapers; click a picture to use it on the desktop and lock screen. Scroll on the icon to step through the library without opening anything, middle-click for a random one.

Discover tab: top-rated photos from Wallhaven by topic (Mountains, Night sky, Forest, Aurora, Space and more) or by search, loading more as you scroll. Pictures are requested at least at your largest screen's resolution (and never below 4K), so they stay sharp on a bigger monitor. Only the safe-for-work General category is used.

Optional: let the accent colour follow each wallpaper (Configure › General). The colour is picked in a perceptual colour space, scored like Android's Material You and checked for WCAG AA contrast in your colour scheme; turning it off restores your scheme exactly.

Needs Python 3 with Pillow (Fedora: python3-pillow, Debian/Ubuntu: python3-pil, Arch: python-pillow). Photos belong to their photographers on wallhaven.cc. The `wall` command inside the widget also works from a terminal. Part of Summit: https://github.com/VicegerentPrince/summit-desktop

---

## 5. Summit (colour scheme)

**Summary:** Slate graphite with a glacier-teal accent, made for dark glass desktops.

**Description:**

A cool, low-glare dark scheme: graphite surfaces (#171c23, #1d232c, #28313d), soft text (#dce3ea) and a teal accent (#4fd1c5), with dark text on highlights for strong contrast. Pairs with the Summit Glass Plasma style and the Liquid Glass widgets, and matches the Summit terminal and editor themes. Part of Summit: https://github.com/VicegerentPrince/summit-desktop

---

## 6. Summit Glass (Plasma style)

**Summary:** The stock Plasma style with a see-through, blurred panel.

**Description:**

Breeze, unchanged except for the panel: its fill is 42% opaque instead of 85%, so the blurred wallpaper shows through like frosted glass. It follows your colour scheme and accent colour. Everything else comes from the stock style at run time, so it keeps up with Breeze updates (the download is 5 KB).

Based on Breeze by the KDE Visual Design Group. Part of Summit: https://github.com/VicegerentPrince/summit-desktop
