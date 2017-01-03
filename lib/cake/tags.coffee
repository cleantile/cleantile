Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
blade = Promise.promisifyAll require "blade"
pkg = require "#{__dirname}/../package"
chalk = require "chalk"

exports.compileTag = compileTag = (opts, dir, tag) ->
  b = "#{dir}/#{tag}.blade"
  h = "#{dir}/#{pkg.name}-#{tag}.html"
  c = "#{dir}/#{pkg.name}-#{tag}.compiled.html"
  blade
    .renderFileAsync "#{__dirname}/../../#{b}", {}
    .then (html) ->
      html.replace /\n((?: |\t)+)\/\*\*(?:\n|.)+?\*\//g, (str, sp) ->
        str.replace(///\n#{sp}///g, "\n").replace("\n/**", "\n#{sp}/**").replace("\n */", "\n#{sp} */")
    .then (html) ->
      fs.writeFileAsync "#{__dirname}/../../#{h}", html
    .then ->
      console.log "Tag #{chalk.blue b} compiled to #{chalk.blue h}"

exports.buildTags = buildTags = (opts) ->
  tags = require "#{__dirname}/../tags"
  builds = for tag in tags
    compileTag opts, tag, tag
  Promise
    .all builds
    .then ->
      console.log chalk.yellow "Compiled all tags."
