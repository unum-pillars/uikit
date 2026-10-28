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
make demo    # compile, then serve the kitchen-sink page on http://localhost:8575
make demo PORT=9000   # the default is 8575: ASCII U (85) and K (75)
make shell   # a shell in the container
```

`src/` and `demo/` are mounted into the container, so editing the theme and re-running
`make demo` (or `make dist`) needs no rebuild of the image.

## Releasing

`VERSION` is the source of truth; `package.json` and `package-lock.json` follow it, and changelog
entries go straight under that version in `CHANGELOG.md`. `make help` lists every target.

```bash
make new               # from a clean main: next version (V=+0.1, +1 or x.y.z, B=branch name), branch, files, changelog section
make release-check     # where the release is up to and what would stop it; changes nothing
make release           # from main: checks, publish to npm, wait for it, tag; safe to run again
make test-release      # tests the scripts in scripts/ against a throwaway repo and a fake registry
```

npm has no test registry: a published version is gone for good, so `release-check` runs first
(changelog section, matching versions, no git dependencies, `make build pack`). The `Jenkinsfile`
runs `make release` on `main`, which does nothing for a version that is already out. It needs the
`github` credential, and `make publish` needs `~/.npmrc` with a token that can publish (on the
Jenkins host, the one typescript-relations uses).

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
