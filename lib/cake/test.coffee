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

exports.test = test = (opts) ->
  cmd = "$(npm bin)/wct"
  if opts["test-local"]
    cmd = "#{cmd} --skip-plugin sauce"
  else if !process.env.SAUCE_USERNAME or process.env.SAUCE_USERNAME.length < 1 or !process.env.SAUCE_ACCESS_KEY
    console.log "#{chalk.red "Not running Sauce Labs tests."}  Set SAUCE_USERNAME and SAUCE_ACCESS_KEY."
    console.log "Only running local tests."
    cmd = "#{cmd} --skip-plugin sauce"
  else if opts["test-sauce"]
    cmd = "#{cmd} --skip-plugin local"
  if opts["persistent"]
    cmd = "#{cmd} -p"
  process.env["FORCE_COLOR"] = true
  exec cmd, {env: process.env}
    .then (res) ->
      console.log res.stdout
      console.log res.stderr
    .catch (err) ->
      console.log res.stdout
      console.log res.stderr
      throw err
