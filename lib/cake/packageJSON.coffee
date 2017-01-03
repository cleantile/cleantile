Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
pkg = require "#{__dirname}/../package"
chalk = require "chalk"

exports.packageJSON = packageJSON = (opts) ->
  deps = require "#{__dirname}/../deps"
  out = JSON.parse JSON.stringify pkg
  out.dependencies = deps "*"
  out.devDependencies = deps "dev"
  fs
    .writeFileAsync "#{__dirname}/../../package.json", JSON.stringify out, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'package.json'}"

exports.bowerJSON = bowerJSON = (opts) ->
  deps = require "#{__dirname}/../deps"
  out = JSON.parse JSON.stringify pkg
  out.dependencies = deps "*", "bower"
  out.devDependencies = deps "dev", "bower"
  fs
    .writeFileAsync "#{__dirname}/../../bower.json", JSON.stringify out, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'bower.json'}"
