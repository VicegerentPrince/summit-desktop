# KDE Store listings

The eight products for https://store.kde.org, with every field of the add form
(https://store.kde.org/product/add). Summit Desktop and Summit Vitals are live; the other six are ready
to add. Build the files with `store/build.sh` (they land in `dist/`); the pictures are in `store/images/`.

The same for every product:
- **Version:** `1.2.0`
- **Link to Source/Code** and **Link to your product homepage:** https://github.com/VicegerentPrince/summit-desktop
- **Product Logo:** a picture of the product, listed for each one below. The store shows the logo as the
  first picture, and Plasma's "Get New" windows use it as the thumbnail.
- **Plasma version**, wherever the form asks: 6
- **Credit for CC-BY licenses**, Facebook, X: leave empty

The store has no summary field. Its lists show the start of the description, so each description below
opens with a sentence that stands on its own.

**Original or Modification** follows the store's rule. "Original" needs 60 to 70% of the work to be
your own. Vitals, Claude Usage, Projects and GitHub are modifications, because their glass is Jack Faith's
component. Summit Glass changes one value in Breeze, which is under the store's 5% mark, so that field
stays blank.

---

## 1. Summit Desktop

- **Category:** Various Plasma 6 Improvements
- **File:** `summit-desktop-1.2.0.tar.gz`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** plasma6, dotfiles, kitty, zsh, glass, wallpaper, fedora
- **Store page:** https://store.kde.org/p/2377643
- **Logo:** summit-desktop.jpg
- **Pictures:** summit-terminal.png, second-screen.jpg, settings.jpg, glass-panel-before-after.png, wallpapers-gallery.png

**Description:**

```text
A fast, glassy Plasma 6 desktop and terminal: Liquid Glass widgets, accent colours taken from your wallpaper, and a kitty + zsh setup that opens in 5 ms.

The complete Summit setup in one download: desktop, panel, widgets, terminal, shell, editor and tool themes. Everything installs for your user only (no root), can be re-run safely, and backs up anything it replaces.

Desktop
- Liquid Glass clock, calendar, weather, music and timer widgets by Jack Faith (jaxparrow07), installed from his GitHub at a pinned version with fixes and new features: the clock no longer redraws at 60 fps (23% of a CPU core down to under 1%), the music widget uses a quarter of the CPU and goes quiet when nothing is playing, the timer's wheels melt into a ring when you press Play, and the glass no longer turns black after login.
- More cards in the same glass: Vitals (pick your figures: CPU, GPU, memory, swap, disk), Claude Usage (Claude Code plan limits), Projects (your latest git projects), GitHub (builds, pull requests, what needs you) and a Wallpapers gallery for the panel with endless Wallhaven photos at your screen's resolution.
- Every card moves only when something changes, so a card at rest costs nothing. Clear Liquid or soft Frosted glass, with sliders, on each card's Appearance page.
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
- **File:** `summit-vitals-1.2.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, system-monitor, cpu, temperature, glass
- **Store page:** https://store.kde.org/p/2377656
- **Logo:** vitals-card.png
- **Pictures:** vitals-settings.png, widgets-on-desktop.jpg

**Description:**

```text
A calm system card in the Liquid Glass style: pick three figures from CPU, GPU, memory, swap and free disk, with network speed, temperatures and battery below, on thin bars that turn amber and red only when something needs attention. Reads Plasma's own system monitor service every two seconds, and numbers move only when they change, so it stays light.

- A Readings page chooses what the card shows, and which graphics card it reads on a laptop with two.
- A dedicated GPU that is asleep reads Off: the card never wakes it to take a reading.
- Resizable; the layout scales with the card.
- Appearance settings for the glass: clear Liquid or soft Frosted, tint, blur and refraction, solid, light or dark.
- Inter Display is included, so it looks the same on any system.

The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. His clock, calendar, weather and music widgets are on this store: https://store.kde.org/u/jaxparrow07. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 3. Summit Claude Usage

- **Category:** Plasma 6 Monitoring
- **File:** `summit-claude-usage-1.2.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, claude, claude-code, glass
- **Logo:** claude-card.png
- **Pictures:** widgets-on-desktop.jpg

**Description:**

```text
Shows how much of your Claude plan's 5-hour window and weekly allowance you have used, and when each resets, with bars that turn amber at 70% and red at 90% (both set on its Readings page).

How it gets the numbers: Claude Code passes its plan limits to its status line. The widget includes a status line script that shows model, folder, git branch, context and limits in Claude Code, and saves the two figures to ~/.cache/summit/claude-usage.json for the card. Nothing is fetched from the network and no credentials are read.

Setup: right-click the card › Configure › Setup, copy the snippet into ~/.claude/settings.json. Needs Claude Code and jq.

Not affiliated with or endorsed by Anthropic. The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. His own widgets are on this store: https://store.kde.org/u/jaxparrow07. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 4. Summit Projects

- **Category:** Plasma 6 Applets
- **File:** `summit-projects-1.2.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, git, developer, projects, glass
- **Logo:** projects-card.png
- **Pictures:** second-screen.jpg

**Description:**

```text
The git projects you worked in last, on a Liquid Glass card: branch, uncommitted changes, commits not pushed yet, and your commits per day over the last week.

Click a project for a terminal there, or the editor button to open it in VS Code, Cursor, VSCodium, Zed, Kate or Sublime Text. Choose your folders, how many rows and which terminal and editor in its settings. Read-only and offline: git runs without taking locks, so a check never changes a repository.

Needs git. The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. Glyphs: Octicons by GitHub Inc., MIT License. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 5. Summit GitHub

- **Category:** Plasma 6 Applets
- **File:** `summit-github-1.2.0.plasmoid`
- **Original or Modification:** Modification
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, github, ci, pull-requests, glass
- **Logo:** github-card.png
- **Pictures:** links-settings.png, second-screen.jpg

**Description:**

```text
Your GitHub day on a Liquid Glass card: builds of the repositories you pushed to last, your open pull requests with their checks, and the notifications that are about you.

It uses your gh login and keeps nothing else: no token to paste, and the last result stays readable offline. Choose the sections and how often it refreshes in its settings.

Links open in the Google Chrome profile that matches your GitHub email, so work and personal accounts stay apart. Pick another profile or your default browser on the Links page.

Needs the GitHub CLI (gh auth login). The glass is Liquid Glass by Jack Faith (jaxparrow07), used under GPL-3.0: https://github.com/jaxparrow07/liquidglass-kde-widgets. Glyphs: Octicons by GitHub Inc., MIT License. Inter Display is by Rasmus Andersson (SIL Open Font License). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 6. Summit Wallpapers

- **Category:** Plasma 6 Applets
- **File:** `summit-wallpapers-1.2.0.plasmoid`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** plasma6, widget, plasmoid, wallpaper, wallhaven, panel
- **Logo:** wallpapers-gallery.png
- **Pictures:** summit-desktop.jpg

**Description:**

```text
A wallpaper gallery for the panel: your library plus endless top-rated Wallhaven photos at your screen's resolution.

Click the panel icon for a gallery of ~/Pictures/Wallpapers; click a picture to use it on the desktop and lock screen. Scroll on the icon to step through the library without opening anything, middle-click for a random one.

Discover tab: top-rated photos from Wallhaven by topic (Mountains, Night sky, Forest, Aurora, Space and more) or by search, loading more as you scroll. Pictures are requested at least at your largest screen's resolution (and never below 4K), so they stay sharp on a bigger monitor. Only safe-for-work pictures are requested: the General category, plus Anime for your own searches, with fan-service tags left out.

Optional: let the accent colour follow each wallpaper (Configure › General). The colour is picked in a perceptual colour space, scored like Android's Material You and checked for WCAG AA contrast in your colour scheme; turning it off restores your scheme exactly.

Needs Python 3 with Pillow (Fedora: python3-pillow, Debian/Ubuntu: python3-pil, Arch: python-pillow). Photos belong to their photographers on wallhaven.cc. The wall command inside the widget also works from a terminal. Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 7. Summit (colour scheme)

- **Category:** Plasma Color Schemes
- **File:** `Summit.colors`
- **Original or Modification:** Original
- **Licence:** GPLv3
- **Tags:** colorscheme, dark, teal, graphite
- **Logo:** colours-settings.png
- **Pictures:** summit-desktop.jpg

**Description:**

```text
A cool, low-glare dark scheme: graphite surfaces (#171c23, #1d232c, #28313d), soft text (#dce3ea) and a teal accent (#4fd1c5), with dark text on highlights for strong contrast. Pairs with the Summit Glass Plasma style and the Liquid Glass widgets, and matches the Summit terminal and editor themes. Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```

---

## 8. Summit Glass (Plasma style)

- **Category:** Plasma Themes
- **File:** `summit-glass-1.2.0.tar.gz`
- **Original or Modification:** leave blank
- **Licence:** LGPLv2
- **Tags:** plasma-style, glass, translucent, blur, panel, breeze
- **Logo:** summit-glass-cover.jpg
- **Pictures:** glass-panel-before-after.png, summit-desktop.jpg

**Description:**

```text
The stock Plasma style with a see-through, blurred panel.

Breeze, unchanged except for the panel: its fill is 42% opaque instead of 85%, so the blurred wallpaper shows through like frosted glass. It follows your colour scheme and accent colour. Everything else comes from the stock style at run time, so it keeps up with Breeze updates (the download is 5 KB).

Based on Breeze by the KDE Visual Design Group (LGPL). Part of Summit: https://github.com/VicegerentPrince/summit-desktop
```
