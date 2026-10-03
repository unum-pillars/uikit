# Changelog

All notable changes to this project are recorded here, newest first. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Publishable as `@unum-pillars/uikit` (public npm package shipping `dist/`): `make pack` previews the tarball, `make publish` publishes from Docker with your `~/.npmrc`. Consumers can use the jsDelivr CDN, e.g. `https://cdn.jsdelivr.net/npm/@unum-pillars/uikit@0.1.0/dist/css/uikit.min.css`.
- `LICENSE` (MIT, as in the other pillar repos).
- Initial scaffold: UIkit 3 (`^3.25`) compiled from stock LESS with our theme variables on top (`src/theme.less`).
- The pastel palette, taken from the cycle diagram: `uu-red` `#ffd9d8`, `uu-yellow` `#fff7a1`, `uu-blue` `#cfe4ff`, `uu-grey` `#dfe3e6`, `uu-green` `#c3f8c9`, `uu-orange` `#ffdda6`, `uu-purple` `#f4d9ff`, with dark text (`#3e3d40`) throughout.
- `uu-<color>` modifier classes for anything colorable (buttons with hover/active states, labels, badges, alerts, cards, table rows, plain elements), plus `uu-<color>-text`.
- UIkit's semantic names mapped onto the hues: danger = red, warning = orange, success = green, primary = blue, secondary = grey.
- Palette swatches on the demo page.
- Docker and make workflow: `make build|dist|css|demo|shell|clean|tag|untag`; nothing is installed locally.
- Kitchen-sink demo page (`demo/index.html`) served by `make demo` on http://localhost:8575 (`PORT=` to change it; 8575 is ASCII U and K).
- Build outputs `dist/css/uikit.css`, `dist/css/uikit.min.css`, `dist/js/uikit.min.js`, `dist/js/uikit-icons.min.js` (gitignored).
