Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
chalk = require "chalk"
pkg = require "#{__dirname}/lib/package"

task "package.json", "Write package.json", (opts) ->
  packageJSON opts

task "tags:build", "Build all of the tags for CleanTile", (opts) ->
  tags = require "#{__dirname}/lib/tags"
  for tag in tags
    compileTemplate opts, tag

packageJSON = (opts) ->
  deps = require "#{__dirname}/lib/deps"
  pkg.dependencies = deps "*"
  pkg.devDependencies = deps "dev"
  fs
    .writeFileAsync "#{__dirname}/package.json", JSON.stringify pkg, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'package.json'}"

compileTemplate = (opts, tag) ->
  blade
    .renderFileAsync "#{__dirname}/#{tag}/#{tag}.blade", {}
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/#{tag}/#{pkg.name}-#{tag}.html", html
    .then ->
      b = "#{tag}/#{tag}.blade"
      h = "#{tag}/#{pkg.name}-#{tag}.html"
      console.log "Compiled #{chalk.blue b} to #{chalk.blue h}"
