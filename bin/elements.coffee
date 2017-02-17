Promise = require "bluebird"
blade = Promise.promisifyAll require "blade"
fs = Promise.promisifyAll require "fs.extra"
path = require "path"

###
Describes a Polymer element that is part of CleanTile.
@todo Consider namespacing (to link Element/Elements) to improve documentation output.  Apply to other scripts.
###
class Element

  ###
  @property {String} name this file's name
  @param {Object} opts options to configure the file copy.
  @option opts {String} fileDir the directory the file is in, relative to the repository root.  Defaults to `name`.
  @option opts {Boolean} noDuplicate if `false`, a copy of the file will be stored in the root folder of the output.
    Defaults to `false`.
  ###
  constructor: (@name, @opts={}) -> yes

  ###
  Shared compilation function.
  @param {Object} opts the options passed to the program
  @param {String, Boolean} fileDir the output directory.  `false` or empty to use `opts.fileDir`
  @param {Boolean} isCopy set to `true` if this file will be stored in the top-level directory.
  @return {Promise} resolves when the file is compiled.
  ###
  _compile: (opts, fileDir=false, isCopy=false) ->
    opts = Object.assign {}, opts, @opts
    opts.fileDir ?= @name
    if fileDir is false then fileDir = opts.fileDir
    html = null
    ###
    Make pathVar point one directory higher than the distribution directory.  This will point to "bower_components"
    when installed.
    ###
    pathVar = "../".repeat ((arr = fileDir.split("/")) ? []).length + (if arr.pop() isnt "" then 1 else 0)
    # If installing documentation, point to distribution directory + "bower_components"
    if opts.distDirectory then pathVar = pathVar.replace("../", "")+opts.distDirectory
    opts.previous ?= Promise.resolve()
    blade
      .renderFileAsync path.join("#{__dirname}/../", opts.fileDir, "#{@name}.blade"),
        pkg: opts.name
        unified: opts.unified
        path: pathVar
        isCopy: isCopy
      .then (h) ->
        html = h
        opts.previous
      .then ->
        fs.mkdirpAsync path.join opts.dist, opts.outdir, fileDir
      .then =>
        fs.writeFileAsync path.join(opts.dist, opts.outdir, fileDir, "#{opts.prefix}#{@name}.html"), html

  ###
  Compile the element's Blade definition into an HTML file.
  @param {Object} opts the options passed to the program
  @return {Promise} resolves when the file is compiled.
  ###
  compile: (opts) ->
    @_compile opts, false, false

  ###
  Compile the element's Blade definition into an HTML file located in the root output directory.
  @param {Object} opts the options passed to the program
  @return {Boolean, Promise} `false` if the duplicate shouldn't be created.
    Otherwise, resolves when the file is compiled.
  ###
  compileDuplicate: (opts) ->
    opts = Object.assign {}, opts, @opts
    return false if opts.noDuplicate is true
    @_compile opts, "", true

  ###
  Read the manifest file for this element
  @param {Object} opts the options passed to the build script
  @return {Object} the element's manifest
  @todo Depending on `opts.manager`, read `package.json`
  ###
  manifest: (opts) ->
    opts = Object.assign {}, opts, @opts
    opts.fileDir ?= @name
    require path.join "#{__dirname}/../", opts.fileDir, "bower.json"

  ###
  Find the element's description.
  @param {Object} opts options passed to the build script
  @return {Promise<String>} the element's description.
  ###
  description: ->
    try
      return Promise.resolve @manifest(opts).description
    catch error
      return Promise.resolve ""

  ###
  Find this element's dependencies.
  @param {Object} opts options passed to the build script
  @return {Promise<Object>} this element's dependencies
  ###
  deps: (opts) ->
    try
      return Promise.resolve @manifest(opts).dependencies
    catch error
      return Promise.resolve {}

  ###
  Find this element's development dependencies.
  @param {Object} opts options passed to the build script
  @return {Promise<Object>} this element's development dependencies
  ###
  devDeps: (opts) ->
    try
      return Promise.resolve @manifest(opts).devDependencies
    catch error
      return Promise.resolve {}

###
Compiles Polymer elements from Blade source files.
@todo Consider changing `@core`, etc. to functions, as they don't show up in Codo.  Apply to other build scripts.
###
class Elements

  @Element = Element

  ###
  @property {Array<Element>} the core elements of CleanTile that are distributed.  See {Element}.
  ###
  @core = [
    new Element "container"
    new Element "pane"
    new Element "split"
    new Element "tab"
    new Element "tabs"
    new Element "view-behavior"
  ]

  ###
  @property {Array<Element>} elements that are used for demos.  See {Element}.
  ###
  @demoElements = [
    new Element "blank-view",
      fileDir: "demo/blank-view"
    new Element "text-view",
      fileDir: "demo/text-view"
  ]

  ###
  @property {Array<Element>} elements that are used for testing.  See {Element}.
  ###
  @testElements = [
    @demoElements...
  ]

  ###
  Compile a set of elements into HTML files.
  @param {Array<Element>} elements the elements to compile.  See {Element}.
  @param {Object} opts the options passed to the program
  @return {Array<Promise>}
  ###
  @compile = (elements, opts) ->
    compiles = []
    for element in elements
      compiles.push element.compile opts
      if (compile = element.compileDuplicate opts) isnt false then compiles.push compile
    compiles

module.exports = Elements
