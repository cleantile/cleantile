Promise = require "bluebird"
{exec} = require "child-process-promise"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
chalk = require "chalk"
pkg = require "#{__dirname}/lib/package"
glob = require "glob-promise"

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
  vulcan = new Vulcanizer {redirects, inlineScripts: yes, inlineCss: yes}
  vulcan.processAsync = Promise.promisify vulcan.process
  _vulcanize = vulcan

option "-l", "--test-local", "Only run tests locally"
option "-s", "--test-sauce", "Only run tests on Sauce Labs"
option "-p", "--persistent", "Run tests in persistent mode"

option "", "--no-build", "Skip building files"

task "all", (opts) ->
  all opts

all = (opts) ->
  packageJSON opts
    .then ->
      Promise.all [
        buildDemos opts
        buildTests opts
      ]

option "", "--no-vulcanize", "Prevents files from being vulcanized"

task "package.json", "Write package.json", (opts) ->
  packageJSON opts

task "tags:build", "Build all of the tags for CleanTile", (opts) ->
  buildTags opts

buildTags = (opts) ->
  tags = require "#{__dirname}/lib/tags"
  builds = for tag in tags
    compileTemplate opts, tag, tag
  Promise.all builds
    
task "demos:build", "Build all of the demos for CleanTile", (opts) ->
  buildDemos opts

buildDemos = (opts) ->
  Promise
    .all [
      buildTags opts
      compileTemplate opts, "demo/text-view", "text-view"
    ]
    .then ->
      Promise.all [
        compileDemo opts, "demo/pane"
        compileDemo opts, "demo/split"
      ]

task "test:build", "Compile the testing files", (opts) ->
  buildTests opts

buildTests = (opts) ->
  Promise
    .all [
      compileTests opts, "test/"
      compileTests opts, "split/test/"
    ]

task "test", "Run tests via Web Component Tester", (opts) ->
  test opts

test = (opts) ->
  Promise
    .resolve null
    .then ->
      all(opts) unless opts["no-build"]
    .then ->
      cmd = "$(npm bin)/wct"
      if opts["test-local"]
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
    .catch (res) ->
      console.log res.stdout
      console.log res.stderr

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

compileTemplate = (opts, dir, tag) ->
  blade
    .renderFileAsync "#{__dirname}/#{dir}/#{tag}.blade", {}
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/#{dir}/#{pkg.name}-#{tag}.html", html
    .then ->
      b = "#{dir}/#{tag}.blade"
      h = "#{dir}/#{pkg.name}-#{tag}.html"
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

compileTests = (opts, dir) ->
  Promise
    .resolve glob "#{__dirname}/#{dir}*.blade"
    .map (t) -> compileTest opts, t
    .then (files) ->
      console.log "Compiled all tests in #{chalk.blue dir} (#{chalk.yellow files.length} files)"

compileTest = (opts, source) ->
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
