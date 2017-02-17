PromiseBar = require "promise.bar"
Promise.bar = (args...) -> PromiseBar.all args...

###
Compiles distributable versions of CleanTile.
###
class BuildCommand

  ###
  @property {Object} contains CLI arguments and internal options.
  ###
  opts: null

  ###
  @param {Object} opts the options passed to the build script.
  ###
  constructor: (opts) ->
    @opts = Object.assign {}, opts

  ###
  Builds Clean Tile for a production build, including only distributed elements.
  @return {Promise} resolves when Clean Tile fully built.
  ###
  buildCleantile: ->
    manifest = require "./manifest"
    elements = require "./elements"
    metafiles = require "./metafiles"
    outdir = require "./outdir"
    opts = Object.assign {}, @opts,
      outdir: "#{@opts.manager}/cleantile"
      unified: yes
    setup = Promise.bar [outdir.create opts], {label: "Create Directory"}
    opts = Object.assign {}, opts, {previous: setup}
    tags = Promise.bar (elements.compile elements.core, opts), {label: "Compile Elements"}
    manifestFile = Promise.bar [manifest.write manifest.core(elements.core), opts], {label: "Write Manifest"}
    files = Promise.bar (metafiles.copy metafiles.core, opts), {label: "Copy Files"}
    Promise.bar [setup, tags, manifestFile, files], {label: "CleanTile for #{opts.manager}"}

  ###
  Builds Clean Tile for a single-element build.
  @param {Element} element the element to build
  @return {Promise} resolves when this element has finished building
  ###
  buildElement: (element) ->
    manifest = require "./manifest"
    elements = require "./elements"
    metafiles = require "./metafiles"
    outdir = require "./outdir"
    opts = Object.assign {}, @opts,
      outdir: "#{@opts.manager}/#{element.name}"
      unified: no
    setup = outdir.create opts
    opts = Object.assign {}, opts,
      previous: setup
    tag = elements.compile [element], opts
    files = Promise.all (metafiles.copy metafiles.standard, opts)
    manifestFile = manifest.write manifest.forElement(element), opts
    if opts.verbose
      Promise.bar [setup, tag, files, manifestFile], {label: "#{element.name}"}
    else
      Promise.all [setup, tag, files, manifestFile]

  ###
  Build all Clean Tile elements as seperate packages.
  @return {Promise} resolves when all elements have been built.
  ###
  buildElements: ->
    elements = require "./elements"
    builds = (@buildElement element for element in elements.core)
    Promise.bar builds, {label: "Individual Elements for #{@opts.manager}"}

  ###
  Determines if `pkg` refers to an element that should be built.
  @param {String} pkg the package requested to build, e.g. `build <package>`
  @return {Boolean, Element} the element the user requested to build.  If no element requested, `false`.
  ###
  shouldBuildElement: (pkg) ->
    elements = require "./elements"
    for element in elements.core when element.name is pkg
      return element

module.exports = BuildCommand
