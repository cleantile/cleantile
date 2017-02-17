Promise = require "bluebird"
fs = Promise.promisifyAll require "fs.extra"
path = require "path"

###
Describes a single file that can be directly copied into a distribution.
###
class MetaFile

  ###
  @property {String} this file's name
  ###
  name: ""

  ###
  @property {String} name this file's name
  @param {Object} opts options to configure the file copy.
  @option opts {String} fileDir the path to the file's directory relative to the repository root, defaulting to `""`.
  @option opts {String} fileOutDir the path to the file's output directory, relative to the build directory.  Defaults
    to matching `fileDir`.
  ###
  constructor: (@name, @opts={}) ->

  ###
  Copy this metafile into a distribution directory.
  @param {Object} opts the options passed to the program
  @return {Promise} resolves once the file is copied
  ###
  copy: (opts) ->
    opts = Object.assign {}, opts, @opts
    opts.fileDir ?= ""
    opts.fileOutDir ?= opts.fileDir
    opts.previous ?= Promise.resolve()
    opts.previous
      .then =>
        fs.copyAsync path.join("#{__dirname}/../", opts.fileDir, @name),
          path.join(opts.dist, opts.outdir, opts.fileOutDir, @name)

###
Copies standalone files ({MetaFile}) into the build.
###
class MetaFiles

  @MetaFile = MetaFile

  ###
  @property {Array<MetaFile>} files that are needed in any distribution of CleanTile.  See {MetaFile}.
  ###
  @standard = [
    new MetaFile "CHANGELOG.md"
    new MetaFile "LICENSE"
  ]

  ###
  @property {Array<MetaFile>} files that are needed for a distribution of CleanTile that contains all components.
    See {MetaFile}.
  ###
  @core = [
    @standard...
    new MetaFile "README.md"
  ]

  ###
  Copies metafiles into a build directory.
  @param {Array<MetaFile>} files the files to copy.  See {MetaFile}.
  @param {Object} opts the options passed to the program
  @return {Array<Promise>} promises that resolve as each file is copied.
  ###
  @copy = (files, opts) -> (file.copy(opts) for file in files)

module.exports = MetaFiles
