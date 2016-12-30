Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
chalk = require "chalk"
pkg = require "#{__dirname}/lib/package"

task "all", (opts) ->
  packageJSON opts
    .then ->
      buildDemos opts

option "", "--no-vulcanize", "Prevents files from being vulcanized"

task "package.json", "Write package.json", (opts) ->
  packageJSON opts

task "tags:build", "Build all of the tags for CleanTile", (opts) ->
  buildTags opts

buildTags = (opts) ->
  tags = require "#{__dirname}/lib/tags"
  builds = for tag in tags
    compileTemplate opts, tag
  Promise.all builds
    
task "demos:build", "Build all of the demos for CleanTile", (opts) ->
  buildDemos opts

_vulcanize = no
vulcanize = ->
  return _vulcanize if _vulcanize
  pkg = require "./package"
  path = require "path"
  Vulcanizer = require "vulcanize"
  deps = {}
  deps[p] = v for p, v of pkg.devDependencies
  deps[p] = v for p, v of pkg.dependencies
  redirects = []
  for p, v of deps
    redirects.push "#{path.resolve "../"+p}|#{__dirname}/node_modules/#{p}"
    if p.indexOf("@") is 0
      plain = p.replace(/^\@[^\/]+\//, "")
      redirects.push "#{path.resolve "../"+plain}|#{__dirname}/node_modules/#{p}"
  vulcan = new Vulcanizer {redirects}
  vulcan.processAsync = Promise.promisify vulcan.process
  _vulcanize = vulcan

buildDemos = (opts) ->
  buildTags opts
    .then ->
      Promise.all [
        compileDemo opts, "demo/sample"
      ]

packageJSON = (opts) ->
  deps = require "#{__dirname}/lib/deps"
  pkg.dependencies = deps "*"
  pkg.devDependencies = deps "dev"
  fs
    .writeFileAsync "#{__dirname}/package.json", JSON.stringify pkg, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'package.json'}"

# Blade filter for stylus without `<script>` tags
# See https://github.com/bminer/node-blade/blob/master/lib/filters.js
plainStylus = (text, opts={}) ->
  ret = ""
  require("stylus").render text, opts, (err, css) ->
    throw err if err
    ret = "\n#{css}"
  ret

compileTemplate = (opts, tag) ->
  blade
    .renderFileAsync "#{__dirname}/#{tag}/#{tag}.blade", {}
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/#{tag}/#{pkg.name}-#{tag}.html", html
    .then ->
      b = "#{tag}/#{tag}.blade"
      h = "#{tag}/#{pkg.name}-#{tag}.html"
      console.log "Compiled #{chalk.blue b} to #{chalk.blue h}"

compileDemo = (opts, demo) ->
  b = "#{demo}.blade"
  h = "#{demo}.html"
  blade
    .renderFileAsync b,
      filters:
        "plain-stylus": plainStylus
    .then (html) ->
      fs.writeFileAsync h, html
    .then ->
      console.log "Compiled #{chalk.blue b} to #{chalk.blue h}"
    .then ->
      return if opts["no-vulcanize"]
      vulcan = vulcanize()
      vulcan.processAsync "#{demo}.html"
        .then (html) ->
          fs.writeFileAsync "#{__dirname}/#{demo}.compiled.html", html
        .then ->
          console.log "Vulcanized #{chalk.blue h}"
