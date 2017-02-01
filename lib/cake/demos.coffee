Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
chalk = require "chalk"
{compileTag} = require "./tags"
vulcanize = require "./_vulcanize"

# Blade filter for stylus without `<script>` tags
# See https://github.com/bminer/node-blade/blob/master/lib/filters.js
exports.plainStylus = plainStylus = (text, opts={}) ->
  ret = ""
  require("stylus").render text, opts, (err, css) ->
    throw err if err
    ret = "\n#{css}"
  ret

exports.compileDemo = compileDemo = (opts, demo) ->
  b = "#{demo}.blade"
  h = "#{demo}.html"
  blade
    .renderFileAsync "#{__dirname}/../../#{b}",
      filters:
        "plain-stylus": plainStylus
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/../../#{h}", html
    .then ->
      console.log "Compiled #{chalk.blue b} to #{chalk.blue h}"
    .then ->
      return if opts["no-vulcanize"]
      vulcan = vulcanize()
      vulcan.processAsync "#{__dirname}/../../#{h}"
        .then (html) ->
          fs.writeFileAsync "#{__dirname}/../../#{demo}.compiled.html", html
        .then ->
          console.log "Vulcanized #{chalk.blue h}"

exports.buildDemos = buildDemos = (opts) ->
  Promise
    .all [
      compileTag opts, "demo/text-view", "text-view"
      compileTag opts, "demo/blank-view", "blank-view"
    ]
    .then ->
      Promise.all [
        compileDemo opts, "demo/pane"
        compileDemo opts, "demo/split"
        compileDemo opts, "demo/simple-binding"
        compileDemo opts, "tabs/demo/pane-tabs"
        compileDemo opts, "tabs/demo/split-tabs"
        compileDemo opts, "drag/demo/index"
      ]
