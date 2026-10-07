# KDE Store listings

The six products on https://store.kde.org, with every field of the add form
(https://store.kde.org/product/add). Build the files with `store/build.sh` (they land in `dist/`);
the pictures are in `store/images/`.

The same for every product:
- **Version:** `1.0.0`
- **Link to Source/Code** and **Link to your product homepage:** https://github.com/VicegerentPrince/summit-desktop
- **Product Logo:** `summit-logo.png`
- **Plasma version**, wherever the form asks: 6
- **Credit for CC-BY licenses**, Facebook, X: leave empty

The store has no summary field. Its lists show the start of the description, so each description below
opens with a sentence that stands on its own.

**Original or Modification** follows the store's rule. "Original" needs 60 to 70% of the work to be
your own. Vitals and Claude Usage are modifications, because most of their code is Jack Faith's glass
component. Summit Glass changes one value in Breeze, which is under the store's 5% mark, so that field
stays blank.

---

## 1. Summit Desktop

- **Category:** Various Plasma 6 Improvements
- **File:** `summit-desktop-1.0.0.tar.gz`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** plasma6, dotfiles, kitty, zsh, glass, wallpaper, fedora
- **Pictures** (the first is the cover): summit-desktop.jpg, summit-terminal.png, glass-panel-before-after.png, wallpapers-gallery.png

**Description:**

```text
A fast, glassy Plasma 6 desktop and terminal: Liquid Glass widgets, accent colours taken from your wallpaper, and a kitty + zsh setup that opens in 5 ms.

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

Install: unpack, then run ./install.sh --layout (see README.md for the one dnf line it needs on Fedora). Built and tested on Fedora 44 with Plasma 6.7 (Wayland); other distributions should work with their own package names.

Credits
- Liquid Glass widgets and the glass effect: Jack Faith (jaxparrow07), https://github.com/jaxparrow07/liquidglass-kde-widgets (GPL-3.0). His widgets are on this store too, https://store.kde.org/u/jaxparrow07, and you can support him at https://ko-fi.com/devrinth
- Inter Display, included for the glass widgets: Rasmus Andersson, SIL Open Font License.
- Wallpapers come from https://wallhaven.cc and belong to their photographers; none are included.
- Summit Glass is based on Breeze by the KDE Visual Design Group (LGPL).

Source and issues: https://github.com/VicegerentPrince/summit-desktop
```

---

## 2. Summit Vitals

- **Category:** Plasma 6 Monitoring
- **File:** `summit-vitals-1.0.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, system-monitor, cpu, temperature, glass
- **Pictures** (the first is the cover): vitals-card.png, widgets-on-desktop.jpg

**Description:**

```text
A calm system card in the Liquid Glass style: CPU and memory use, free disk space, network speed, CPU temperature and battery, with thin bars that turn amber and red only when something needs attention. Reads Plasma's own system monitor service every two seconds and has no animations, so it stays light.

- Resizable; the layout scales with the card.
- Appearance settings for the glass (tint, blur, refraction, glass or solid, light or dark).
- Inter Display is included, so it looks the same on any system.

The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. His clock, calendar, weather and music widgets are on this store: https://store.kde.org/u/jaxparrow07. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 3. Summit Claude Usage

- **Category:** Plasma 6 Monitoring
- **File:** `summit-claude-usage-1.0.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, claude, claude-code, glass
- **Pictures** (the first is the cover): claude-card.png, widgets-on-desktop.jpg

**Description:**

```text
Shows how much of your Claude plan's 5-hour window and weekly allowance you have used, and when each resets, with bars that turn amber at 70% and red at 90%.

How it gets the numbers: Claude Code passes its plan limits to its status line. The widget includes a status line script that shows model, folder, git branch, context and limits in Claude Code, and saves the two figures to ~/.cache/summit/claude-usage.json for the card. Nothing is fetched from the network and no credentials are read.

Setup: right-click the card › Configure › Setup, copy the snippet into ~/.claude/settings.json. Needs Claude Code and jq.

Not affiliated with or endorsed by Anthropic. The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. His own widgets are on this store: https://store.kde.org/u/jaxparrow07. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 4. Summit Wallpapers

- **Category:** Plasma 6 Applets
- **File:** `summit-wallpapers-1.0.0.plasmoid`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, wallpaper, wallhaven, panel
- **Pictures** (the first is the cover): wallpapers-gallery.png, summit-desktop.jpg

**Description:**

```text
A wallpaper gallery for the panel: your library plus endless top-rated Wallhaven photos at your screen's resolution.

Click the panel icon for a gallery of ~/Pictures/Wallpapers; click a picture to use it on the desktop and lock screen. Scroll on the icon to step through the library without opening anything, middle-click for a random one.

Discover tab: top-rated photos from Wallhaven by topic (Mountains, Night sky, Forest, Aurora, Space and more) or by search, loading more as you scroll. Pictures are requested at least at your largest screen's resolution (and never below 4K), so they stay sharp on a bigger monitor. Only the safe-for-work General category is used.

Optional: let the accent colour follow each wallpaper (Configure › General). The colour is picked in a perceptual colour space, scored like Android's Material You and checked for WCAG AA contrast in your colour scheme; turning it off restores your scheme exactly.

Needs Python 3 with Pillow (Fedora: python3-pillow, Debian/Ubuntu: python3-pil, Arch: python-pillow). Photos belong to their photographers on wallhaven.cc. The wall command inside the widget also works from a terminal. Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 5. Summit (colour scheme)

- **Category:** Plasma Color Schemes
- **File:** `Summit.colors`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** colorscheme, dark, teal, graphite
- **Pictures** (the first is the cover): colours-settings.png, summit-desktop.jpg

**Description:**

```text
A cool, low-glare dark scheme: graphite surfaces (#171c23, #1d232c, #28313d), soft text (#dce3ea) and a teal accent (#4fd1c5), with dark text on highlights for strong contrast. Pairs with the Summit Glass Plasma style and the Liquid Glass widgets, and matches the Summit terminal and editor themes. Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 6. Summit Glass (Plasma style)

- **Category:** Plasma Themes
- **File:** `summit-glass-1.0.0.tar.gz`
- **Original or Modification:** leave blank
- **Licence:** LGPLv2
- **Tags:** plasma-style, glass, translucent, blur, panel, breeze
- **Pictures** (the first is the cover): glass-panel-before-after.png, summit-desktop.jpg

**Description:**

```text
The stock Plasma style with a see-through, blurred panel.

Breeze, unchanged except for the panel: its fill is 42% opaque instead of 85%, so the blurred wallpaper shows through like frosted glass. It follows your colour scheme and accent colour. Everything else comes from the stock style at run time, so it keeps up with Breeze updates (the download is 5 KB).

Based on Breeze by the KDE Visual Design Group (LGPL). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```
