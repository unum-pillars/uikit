# uikit

A port of UIkit 3 to use for our stuff: one themed build, shared by every app.

Nothing in UIkit is edited. `src/theme.less` imports stock UIkit 3 from npm and sets our
variables on top (Less evaluates variables lazily, so the last definition wins). Upgrading UIkit
is a version bump in `package.json`.

## Running

Everything runs in Docker; you only need Docker and make.

```bash
make build   # build the image (once, and after changing package.json)
make dist    # compile dist/css/uikit.css, uikit.min.css and copy dist/js/*
make demo    # compile, then serve the kitchen-sink page on http://localhost:8080
make demo PORT=9000
make shell   # a shell in the container
```

`src/` and `demo/` are mounted into the container, so editing the theme and re-running
`make demo` (or `make dist`) needs no rebuild of the image.

## Using it in an app

Copy `dist/css/uikit.min.css`, `dist/js/uikit.min.js` and `dist/js/uikit-icons.min.js` into the
app, and link them in place of the UIkit 2 files.

## Theming

The palette lives in one block at the top of `src/theme.less`. Shades are named for the color,
never the job: `uu-red`, `uu-yellow`, `uu-blue`, `uu-grey`, `uu-green`, `uu-orange`, `uu-purple`.
Anything colorable takes the same modifier, e.g. `<button class="uk-button uu-red">`,
`<span class="uk-label uu-green">`, `<div class="uk-card uu-blue">`. UIkit's own names land on
the same hues: danger is red, warning is orange, success is green, primary is blue, secondary is
grey. Text on every shade is dark (`#3e3d40`); the pastels are too light for anything else.

Note the apps in `unum-apps` and `opengui` are on UIkit 2.8 (`uk-form`, `uk-navbar-nav`, ...).
UIkit 3 renamed many classes, so adopting this build means migrating each app's templates.
