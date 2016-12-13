Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"

task "package.json", "Write package.json", (opts) ->
  packageJSON opts

packageJSON = (opts) ->
  pkg = require "#{__dirname}/lib/package"
  deps = require "#{__dirname}/lib/deps"
  pkg.dependencies = deps "*"
  pkg.devDependencies = deps "dev"
  fs.writeFileAsync "#{__dirname}/package.json", JSON.stringify pkg, null, 2
