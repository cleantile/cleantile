Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
pkg = require "#{__dirname}/../package"
chalk = require "chalk"

exports.packageJSON = packageJSON = (opts) ->
  deps = require "#{__dirname}/../deps"
  pkg.dependencies = deps "*"
  pkg.devDependencies = deps "dev"
  fs
    .writeFileAsync "#{__dirname}/../../package.json", JSON.stringify pkg, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'package.json'}"
