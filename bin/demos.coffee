path = require "path"
Promise = require "bluebird"
blade = Promise.promisifyAll require "blade"
fs = Promise.promisifyAll require "fs.extra"
glob = require "glob-promise"
{plainStylus} = require "./filters"

###
Describes a single demonstration.
###
class Demo

  ###
  @param {String} path the path to this file
  @param {Element} element **Optional** the element this demo belongs to.  Omit for global demos.
  ###
  constructor: (@path, @element) ->

  ###
  Compile this test file into HTML.
  @param {Object} opts the options passed to the build script.
  @return {Promise} resolves when the file has been written
  ###
  compile: (opts) ->
    repo = path.resolve "#{__dirname}/../"
    out = @path
      .replace repo, "#{opts.dist}/#{opts.outdir}"
      .replace ".blade", ".html"
    html = null
    blade
      .renderFileAsync @path,
        path: path.relative path.dirname(out), "#{opts.dist}/#{opts.outdir}/bower_components/"
        unified: opts.unified
        filters: {"plain-stylus": plainStylus}
      .then (h) ->
        html = h
        Promise.resolve opts.previous
      .then ->
        fs.mkdirpAsync path.dirname out
      .then =>
        fs.writeFileAsync out, html

class Demos

  ###
  Find the top-level demos (in `/demo/`).
  @return {Promise<Array<Demo>>} the demos found.  See {Demo}.
  ###
  @GlobalDemos = ->
    Promise
      .resolve glob "#{__dirname}/../demo/*.blade"
      .map (path) -> new Demo path

  ###
  Find demos local to specific elements.
  @param {Array<Element>} elements the elements to search inside.  See {Element}.
  @return {Promise<Array<Demo>>} the demos found.  See {Demo}.
  ###
  @AllElementDemos = (elements) ->
    Promise
      .resolve elements
      .filter @ElementHasDemos
      .map (element) => @ElementDemos element
      .then (demoArrays) ->
        [].concat demoArrays...

  ###
  Determine if an element has a `demo` folder.
  @param {Element} the element to test.
  @return {Promise<Boolean} `true` if the element has a `demo` folder.
  ###
  @ElementHasDemos = (element) ->
    fs
      .accessAsync "#{__dirname}/../#{element.opts.fileDir || element.name}/demo/"
      .then -> yes
      .catch (err) -> no

  ###
  Find the demos for a specific element.
  @param {Element} the element to search in.
  @return {Promise<Array<Demo>>} the demos found.  See {Demo}.
  ###
  @ElementDemos = (element) ->
    Promise
      .resolve glob "#{__dirname}/../#{element.opts.fileDir || element.name}/demo/*.blade"
      .map (path) ->
        new Demo path, element

module.exports = Demos
