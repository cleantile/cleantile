# Building Clean Tile

Clean Tile's build system is organized as a standard NodeJS script.
Build commands and options are set via CLI arguments, parsed via [commander][].

Build steps are built around [Promise][]s, to allow chaining.

The main repository only holds source files.  Compiled files are stored under an output directory, defaulting to
`./dist`.

## Build Commands

> See `bin/build.coffee --help` as well as `bin/build.coffee <command> --help` for all possible options.

- `build <package>`
  - `build cleantile`
    Build the main `cleantile` distribution.
  - `build <element>`
    Build a distribution for a single element (e.g. `split`)
  - `build all`
    Build all of the above packages.
- `test`
  Compile and run automated tests against Clean Tile.
- `docs`
  Build the documentation for Clean Tile.

## Internal Options

Most arguments that build steps use are documented as CLI arguments.
However, build steps also take a few extra options that are set internally.

- String `outdir`
  A directory inside `dist` to write compiled files to
- Boolean `unified`
  Used when building elements.  If `unified=true`, then the main `cleantile` distribution is being compiled.
  Otherwise, an individual element (e.g. `split`) is being built.
- [Promise][] `previous`
  Steps should wait for `previous` to resolve before writing files.
- String `distDirectory`
  For documentation, set to `"bower_components/"` to link directly to dependencies.

## Build Steps

Most build functionality is contained in reusable containers.
See the respective classes for further information.

- **Elements** defines the Polymer elements, and compiles them into HTML files.
- **Manifests** writes `package.json`/`bower.json` files
- **MetaFiles** copies standalone files into the build
- **OutDir** creates clean output directories
- **Tests** compiles testing files into the required HTML, and creates `index.html` files to point to tests

## Publishing Documentation

```sh
ssh-agent
ssh-add lib/deploy_key
bin/build.coffee docs --publish
```

[commander]: https://www.npmjs.com/package/commander
[Promise]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
