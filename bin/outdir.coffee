Promise = require "bluebird"
fs = Promise.promisifyAll require "fs.extra"
path = require "path"

###
Manages creating a clean distribution directory.
###
class OutDir

  @clean = (opts) ->
    fs.rmrfAsync path.join opts.dist, opts.outdir

  ###
  Create a new output directory.
  ###
  @create = (opts) ->
    clean = if opts.clean then @clean(opts) else Promise.resolve()
    clean
      .then -> fs.mkdirpAsync path.join opts.dist, opts.outdir

module.exports = OutDir
