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
  deps = [
    "hydrolysis"
    "@polymer/iron-ajax"
    "@polymer/iron-doc-viewer"
    "@polymer/iron-flex-layout"
    "@polymer/iron-selector"
    "@polymer/paper-header-panel"
    "@polymer/paper-styles"
    "@polymer/paper-button"
    "@polymer/marked-element"
    "@polymer/paper-toolbar"
    "@polymer/prism-element"
    "@polymer/iron-meta"
    "@polymer/paper-behaviors"
    "@polymer/paper-material"
    "@polymer/promise-polyfill"
    "marked"
    "@polymer/iron-behaviors"
    "@polymer/paper-ripple"
    "@polymer/iron-a11y-keys-behavior"
    "@polymer/iron-iconset-svg"
    "prism"
  ]
  deps.push p for p, v of pkg.devDependencies
  deps.push p for p, v of pkg.dependencies
  redirects = [
    "#{path.resolve "../iron-icon/s/iron-icons.html"}|#{__dirname}/node_modules/@polymer/iron-icons/iron-icons.html"
    "#{path.resolve "../iron-icons/et-svg/iron-iconset-svg.html"}|#{__dirname}/node_modules/@polymer/iron-iconset-svg/iron-iconset-svg.html"
    "#{path.resolve "../iron-icons/iron-icons.html"}|#{__dirname}/node_modules/@polymer/iron-icons/iron-icons.html"
    "#{path.resolve "../iron-icon/iron-icon.html"}|#{__dirname}/node_modules/@polymer/iron-icon/iron-icon.html"
    "#{__dirname}/node_modules/prism/themes/prism.css|#{__dirname}/node_modules/prismjs-package/themes/prism.css"
    "#{path.resolve "../prism/prism.js"}|#{__dirname}/node_modules/prismjs-package/lib/prism.js"
  ]
  try
    fs.symlinkSync "#{__dirname}/node_modules/prismjs-package", "#{__dirname}/node_modules/prism"
  catch err
    yes
  for p in deps
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
      buildTags opts
    .then ->
      Promise.all [
        tagIndex opts
        docIndex opts
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

task "docs", "Build documentation", (opts) ->
  Promise.join [
    tagIndex opts
    docIndex opts
  ]

tagIndex = (opts) ->
  tags = require "#{__dirname}/lib/tags"
  ind = ""
  for tag in tags
    ind += """
      <link rel="import" href="#{tag}/#{pkg.name}-#{tag}.html" />\n
    """
  fs
    .writeFileAsync "#{__dirname}/cleantile.html", ind
    .then ->
      vulcan = vulcanize()
      vulcan.processAsync "#{__dirname}/cleantile.html"
    .then (html) -> fs.writeFileAsync "#{__dirname}/cleantile.compiled.html", html

docIndex = (opts) ->
  blade
    .renderFileAsync "#{__dirname}/index.blade", {}
    .then (html) -> fs.writeFileAsync "#{__dirname}/index.html", html
    .then ->
      vulcan = vulcanize()
      vulcan.processAsync "#{__dirname}/index.html"
        .then (html) ->
          fs.writeFileAsync "#{__dirname}/index.html", html
        .then ->
          console.log "Vulcanized #{chalk.blue "index.html"}"
    .catch (err) ->
      console.log err

task "demos:build", "Build all of the demos for CleanTile", (opts) ->
  buildDemos opts

buildDemos = (opts) ->
  Promise
    .all [
      buildTags opts
      compileTemplate opts, "demo/text-view", "text-view"
      compileTemplate opts, "demo/blank-view", "blank-view"
    ]
    .then ->
      Promise.all [
        compileDemo opts, "demo/pane"
        compileDemo opts, "demo/split"
        compileDemo opts, "demo/simple-binding"
        compileDemo opts, "tabs/demo/pane-tabs"
        compileDemo opts, "tabs/demo/split-tabs"
      ]

task "test:build", "Compile the testing files", (opts) ->
  buildTests opts

buildTests = (opts) ->
  Promise
    .all [
      compileTests opts, "test/"
      compileTests opts, "split/test/"
      compileTests opts, "tabs/test/"
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
  b = "#{dir}/#{tag}.blade"
  h = "#{dir}/#{pkg.name}-#{tag}.html"
  c = "#{dir}/#{pkg.name}-#{tag}.compiled.html"
  blade
    .renderFileAsync "#{__dirname}/#{b}", {}
    .then (html) ->
      html.replace /\n((?: |\t)+)\/\*\*(?:\n|.)+?\*\//g, (str, sp) ->
        str.replace(///\n#{sp}///g, "\n").replace("\n/**", "\n#{sp}/**").replace("\n */", "\n#{sp} */")
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/#{h}", html
    .then ->
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
