Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
chalk = require "chalk"
vulcanize = require "./_vulcanize"
pkg = require "#{__dirname}/../package"

exports.tagIndex = tagIndex = (opts) ->
  tags = require "#{__dirname}/../tags"
  ind = ""
  for tag in tags
    ind += """
      <link rel="import" href="#{tag}/#{pkg.name}-#{tag}.html" />\n
    """
  fs
    .writeFileAsync "#{__dirname}/../../cleantile.html", ind
    .then ->
      vulcan = vulcanize()
      vulcan.processAsync "#{__dirname}/../../cleantile.html"
    .then (html) -> fs.writeFileAsync "#{__dirname}/../../cleantile.compiled.html", html

exports.docIndex = docIndex = (opts) ->
  blade
    .renderFileAsync "#{__dirname}/../../index.blade", {}
    .then (html) -> fs.writeFileAsync "#{__dirname}/../../index.html", html
    .then ->
      vulcan = vulcanize()
      vulcan.processAsync "#{__dirname}/../../index.html"
        .then (html) ->
          fs.writeFileAsync "#{__dirname}/../../index.html", html
        .then ->
          console.log "Vulcanized #{chalk.blue "index.html"}"
    .catch (err) ->
      console.log err
