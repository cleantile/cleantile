Promise = require "bluebird"
blade = Promise.promisifyAll require "blade"
fs = Promise.promisifyAll require "fs.extra"
chalk = require "chalk"
path = require "path"
{exec, spawn} = require "child-process-promise"
PromiseBar = require "promise.bar"
Promise.bar = (args...) -> PromiseBar.all args...

###
Compiles documentation, and optionally publishes it to `gh-pages`.
###
class DocsCommand

  ###
  @property {Object} contains CLI arguments and internal options.
  ###
  opts: null

  ###
  @property {Object} additional dependencies for the documentation pages.
  ###
  deps:
    "font-roboto": "PolymerElements/font-roboto#^1.0.1"
    "iron-component-page": "PolymerElements/iron-component-page#^1.1.8"

  ###
  @param {Object} opts the options passed to the build script.
  ###
  constructor: (opts) ->
    @opts = Object.assign {}, opts,
      outdir: "docs"
      distDirectory: "bower_components/"
      unified: yes

  ###
  Builds documentation pages for local use, or use on `gh-pages`.
  @param {Object} opts the options passed to the program
  @return {Promise} resolves when the documentation has been built.
  @todo run install via `npm` if using NPM
  ###
  buildDocs: ->
    elements = require "./elements"
    outdir = require "./outdir"
    @opts = Object.assign {}, @opts,
      previous: outdir.create @opts
    Promise
      .resolve @compileDemos elements.core
      .then (compileDemos) =>
        #console.log compileDemos
        Promise.bar [
          @buildElements elements.core, elements.demoElements
          Promise.bar compileDemos, {label: chalk.cyan "Compile Demos"}
          manifest = @writeManifest elements.core
          @installDeps manifest
          @compileBuildDocs()
          @compileIndex()
          @writeLinks elements.core
          #TODO (optionally) publish on gh-pages
        ], {label: chalk.bold "Build docs"}
      .then =>
        if @opts.serve
          @serveFiles()

  ###
  Find and compile both global demos as well as per-element demos.
  @param {Array<Element>} elements the elements to search inside.
  @return {Promise} resolves when all demos have been found and compiled.
  ###
  compileDemos: (elements) ->
    demos = require "./demos"
    Promise
      .all [demos.GlobalDemos(), demos.AllElementDemos elements]
      .then ([globalDemos, elementDemos]) =>
        all = globalDemos.concat elementDemos...
        all.map (demo) => demo.compile @opts

  ###
  Compile a set of elements for documentation.
  @param {Array<Element>} core the primary elements to compile.  See {Element}.
  @param {Array<Element} demos additional elements to compile that are needed for demos.  See {Element}.
  @return {Promise} resolves when all elements have been compiled.
  ###
  buildElements: (core, demos) ->
    elements = require "./elements"
    demoOpts = Object.assign {}, @opts, {noDuplicate: yes}
    Promise.bar [
      Promise.bar (elements.compile core, @opts), {label: chalk.blue.dim "Core Elements"}
      Promise.bar (elements.compile demos, demoOpts), {label: chalk.blue.dim "Demo Elements"}
    ], {label: chalk.blue "Compile Elements"}

  ###
  Write a manifest file (`package.json`/`bower.json`) for the core elements.
  @param {Array<Element>} core the primary elements included in the build.  See {Element}.
  @return {Promise} resolves when the manifest has been written.
  ###
  writeManifest: (core) ->
    manifest = require "./manifest"
    file = manifest.core(core)
    write = file
      .manifest @opts
      .then (obj) =>
        Object.assign obj.devDependencies, @deps
        file.write @opts, obj
    Promise.bar [write], {label: chalk.yellow "Write manifest"}

  ###
  Run `bower install` to install the required packages.
  @param {Promise} manifest a promise that is resolved once the manifest file has been written.
  @return {Promise} resolves when the dependencies have been installed
  ###
  installDeps: (manifest) ->
    install = Promise
      .resolve manifest
      .then =>
        exec "#{__dirname}/../node_modules/.bin/bower install",
          cwd: path.join @opts.dist, "docs"
    Promise.bar [install], {label: chalk.yellow "bower install"}

  ###
  Generate documentation for the build scripts using `codo`.
  @return {Promise} resolves when the documentation has been generated.
  ###
  compileBuildDocs: ->
    codo = @opts.previous
      .then =>
        opts = {cwd: path.resolve("#{__dirname}/../")}
        if @opts.verbose
          opts.stdio = "inherit"
        spawn path.resolve("#{__dirname}/../node_modules/.bin/codo"), [
          "-o", path.join @opts.dist, "docs", "build-docs"
          "-r", "bin/BUILDING.md"
          "-n", "CleanTile Build Script", "-t", "CleanTile Build Script"
          "--quiet", "--private", "bin"
          "-", "bin/BUILDING.md"
          ], opts
    Promise.bar [codo], {label: chalk.green "Document build scripts"}

  ###
  Compile the documentation homepage (`index.html`)
  @return {Promise} resolves when the index file has been compiled.
  ###
  compileIndex: ->
    html = null
    compile = blade
      .renderFileAsync "#{__dirname}/../index.blade",
        path: "bower_components/"
      .then (h) =>
        html = h
        Promise.resolve @opts.previous
      .then =>
        fs.writeFileAsync path.join(@opts.dist, "docs", "index.html"), html
    Promise.bar [compile], {label: chalk.magenta "Compile index.html"}

  ###
  Create `cleantile.html` which links to all of the modules.
  @param {Array<Element>} elements the primary elements to compile.  See {Element}.
  @return {Promise} resolves when the file has been written.
  ###
  writeLinks: (elements) ->
    html = ""
    for element in elements
      html += """
        <link rel="import" href="#{element.opts.fileDir ? element.name}/#{@opts.prefix}#{element.name}.html" />\n
      """
    write = Promise
      .resolve @opts.previous
      .then => fs.writeFileAsync path.join(@opts.dist, "docs", "cleantile.html"), html
    Promise.bar [write], {label: chalk.magenta "Write cleantile.html"}

  serveFiles: ->
    Static = require "node-static"
    file = new Static.Server path.join @opts.dist, "docs"
    require("http")
      .createServer (req, res) ->
        req
          .addListener "end", ->
            file.serve req, res
          .resume()
      .listen @opts.serve, =>
        console.log "Documentation hosted at http://localhost:#{@opts.serve}/"

module.exports = DocsCommand
