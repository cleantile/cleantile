path = require "path"
Promise = require "bluebird"
fs = Promise.promisifyAll require "fs.extra"

###
Describes a `package.json`/`bower.json` file that should be built.
###
class Manifest

  ###
  Fetch the package name to use in the manifest.
  @param {Object} opts options passed to the build script.
  @return {Promise<String>}
  ###
  name: (opts) -> Promise.resolve ""

  ###
  Fetch a description to include in the manifest.
  @param {Object} opts options passed to the build script.
  @return {Promise<String>}
  ###
  description: (opts) -> Promise.resolve ""

  ###
  Fetch the package dependencies.
  @param {Object} opts options passed to the build script
  @return {Promise<Object>} the package dependencies
  @todo Depending on `opts.manager`, return NPM version.
  ###
  deps: (opts) ->
    Promise.resolve
      "polymer": "Polymer/polymer#^1.6.0"

  ###
  Fetch the package development dependencies.
  @param {Object} opts options passed to the build script
  @return {Promise<Object>} the development dependencies
  @todo Depending on `opts.manager`, return NPM version.
  ###
  devDeps: (opts) -> Promise.resolve {}

  ###
  Construct the manifest structure.
  @param {Object} opts options passed to the build script
  @return {Promise<Object>} the manifest file as an object.
  @todo Depending on `opts.manager`, return NPM version.
  ###
  manifest: (opts) ->
    Promise
      .all [@name(opts), @description(opts), @deps(opts), @devDeps(opts)]
      .then ([name, description, deps, devDeps]) ->
        {name, description, dependencies: deps, devDependencies: devDeps}

  ###
  Write a manifest out to the proper file
  @param {Object} opts options passed to the build script
  @param {Object} manifest the manifest file to write.  See {Manifest#manifest}.
  @return {Promise} resolves when the manifest file has been written.
  @todo Depending on `opts.manager`, write `package.json`
  ###
  write: (opts, manifest) ->
    opts.previous ?= Promise.resolve()
    outDir = path.join(opts.dist, opts.outdir)
    opts.previous
      .then ->
        fs.mkdirpAsync outDir
      .then ->
        json = JSON.stringify manifest, null, 2
        fs.writeFileAsync path.join(outDir, "bower.json"), json

###
A {Manifest} for builds that include all elements.
###
class GlobalManifest extends Manifest

  ###
  @param {Array<Element>} elements the elements included in the build.  See {Element}.
  ###
  constructor: (@elements) ->

  name: (opts) -> Promise.resolve opts.name

  description: (opts) ->
    pkg = require "#{__dirname}/../package.json"
    Promise.resolve pkg.description

  ###
  Remove references to local packages.
  @param {Object} opts the options passed to the build script
  @param {Object} deps the object of dependencies
  @return {Object} the allowed dependencies.
  ###
  cleanDeps: (opts, deps) ->
    out = {}
    for own dep, version of deps
      continue if version[0] is "."
      out[dep] = version
    out

  deps: (opts) ->
    deps = @elements.map (element) -> element.deps opts
    deps.push super opts
    Promise.all(deps)
      .then (deps) ->
        Object.assign {}, deps...
      .then (deps) => @cleanDeps opts, deps

  devDeps: (opts) ->
    deps = @elements.map (element) -> element.devDeps opts
    deps.push super opts
    Promise.all(deps)
      .then (deps) ->
        Object.assign {}, deps...
      .then (deps) => @cleanDeps opts, deps

###
A {Manifest} for a single-element build.

@todo handle references to local elements in deps and devDeps
###
class ElementManifest extends Manifest

  ###
  @param {Element} the element included in the build.
  ###
  constructor: (@element) ->

  name: (opts) -> Promise.resolve opts.prefix + @element.name

  description: (opts) -> @element.description opts

  deps: (opts) ->
    Promise
      .all [super(opts), @element.deps opts]
      .then ([s, e]) -> Object.assign {}, s, e

  devDeps: (opts) ->
    Promise
      .all [super(opts), @element.devDeps opts]
      .then ([s, e]) -> Object.assign {}, s, e

###
Writes `package.json` or `bower.json` files depending on the current package manager.
###
class Manifests

  @Manifest = Manifest

  @GlobalManifest = GlobalManifest

  ###
  The global manifest file when installing all of CleanTile.
  @param {Array<Element>} elements the elements included in the build.  See {Element}.
  @return {Manifest}
  ###
  @core = (elements) -> new GlobalManifest elements

  ###
  Prepares a manifest file for a specific element.
  @param {Element} element the element to build the manifest for.  See {Element}.
  @return {Manifest}
  ###
  @forElement = (element) -> new ElementManifest element

  ###
  @param {Manifest} manifest the manifest file to write.
  @param {Object} opts the options passed to the program
  @return {Promise} resolves when the file is written
  ###
  @write = (manifest, opts) ->
    manifest
      .manifest opts
      .then (obj) ->
        manifest.write opts, obj

module.exports = Manifests
