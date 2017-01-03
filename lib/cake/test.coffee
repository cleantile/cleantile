vulcanize = require "./_vulcanize"
Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
{exec} = require "child-process-promise"
glob = require "glob-promise"
chalk = require "chalk"

exports.compileTest = compileTest = (opts, source) ->
  out = source.replace(".blade", ".html")
  blade
    .renderFileAsync source, {}
    .then (html) ->
      fs.writeFileAsync out, html
    .then ->
      return if opts["no-vulcanize"]
      vulcan = vulcanize()
      vulcan
        .processAsync out
        .then (html) ->
          fs.writeFileAsync out, html

exports.compileTests = compileTests = (opts, dir) ->
  Promise
    .resolve glob "#{__dirname}/../../#{dir}*.blade"
    .map (t) -> compileTest opts, t
    .then (files) ->
      console.log "Compiled all tests in #{chalk.blue dir} (#{chalk.yellow files.length} files)"

exports.buildTests = buildTests = (opts) ->
  Promise
    .all [
      compileTests opts, "test/"
      compileTests opts, "split/test/"
      compileTests opts, "tabs/test/"
    ]
