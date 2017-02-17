path = require "path"
Promise = require "bluebird"
blade = Promise.promisifyAll require "blade"
fs = Promise.promisifyAll require "fs.extra"
glob = require "glob-promise"
interpolatedCoffeeScript = require "@codelenny/blade-interpolated-coffee"

quote = (str) -> "\"#{str}\""

###
Describes a single testing file.
###
class Test
  ###
  @param {String} path the path to this file
  @param {Element} element **Optional** the element this test belongs to.  Omit for global tests.
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
    opts.previous ?= Promise.resolve()
    blade
      .renderFileAsync @path,
        path: path.relative out, "#{repo}/#{opts.dist}"
      .then (h) ->
        html = h
        opts.previous
      .then ->
        fs.mkdirpAsync path.dirname out
      .then =>
        fs.writeFileAsync out, html

###
Finds and compiles testing files.

Test files are expected to be [Blade](https://github.com/bminer/node-blade) files written for
[WCT](https://github.com/Polymer/web-component-tester).

Test files are either "global" or for a specific element.  Methods are provided for each category seperately.
###
class Tests

  @Test = Test

  ###
  Find the top-level tests (in `/test/`).
  @return {Promise<Array<Test>>} the tests found.  See {Test}.
  ###
  @GlobalTests = ->
    Promise
      .resolve glob "#{__dirname}/../test/test-*.blade"
      .map (path) -> new Test path

  ###
  Determine if the given element has test files.
  @param {Element} element the element to find tests for
  @return {Promise<Boolean>} `true` if the element has testing files
  ###
  @ElementHasTests = (element) ->
    fs
      .accessAsync "#{__dirname}/../#{element.opts.fileDir || element.name}/test/"
      .then -> yes
      .catch (err) -> no

  ###
  Find tests for a specific element.
  @param {Element} element the element to find tests for
  @return {Promise<Array<Test>>} the tests found for the element specified.  See {Test}.
  ###
  @FindTests = (element) ->
    Promise
      .resolve glob "#{__dirname}/../#{element.opts.fileDir || element.name}/test/test-*.blade"
      .map (path) ->
        new Test path, element

  ###
  Render `index.html` for a specific set of tests
  @param {Array<String>} paths relative paths to test files to include
  @param {String} title the title to name the document
  @return {Promise<String>} the compiled HTML file
  ###
  @RenderIndex = (paths, title) ->
    blade
      .renderFileAsync "#{__dirname}/../lib/testIndex.blade",
        files: "    "+paths.join(",\n      ")
        title: title
        filters:
          "_coffeescript": interpolatedCoffeeScript
          "_coffeescript.raw": interpolatedCoffeeScript.raw

  ###
  Write the global `index.html` for all tests.
  @param {Array<Element>} elements all elements that have their own tests files (with an `index.html` file).
    See {Element}.
  @param {Array<Test>} tests the global tests.  See {Test}.
  @param {Object} opts the options passed to the build script.
  @return {Promise} resolves when the index has been written.
  ###
  @WriteGlobalIndex = (elements, tests, opts) ->
    from = path.resolve "#{__dirname}/../test"
    elements = elements.map (element) ->
      quote path.relative from, "#{__dirname}/../#{element.opts.fileDir || element.name}/test/index.html"
    tests = tests.map (test) ->
      quote path.relative from, test.path.replace ".blade", ".html"
    html = null
    @RenderIndex elements.concat(tests), "Global Tests"
      .then (h) ->
        html = h
        if opts.previous then Promise.resolve(opts.previous) else Promise.resolve()
      .then ->
        fs.mkdirpAsync "#{opts.dist}/#{opts.outdir}/test/"
      .then ->
        fs.writeFileAsync "#{opts.dist}/#{opts.outdir}/test/index.html", html

  ###
  Write `index.html` for a specific element
  @param {Element} element the element to write the index file for
  @param {Array<Test>} tests the testing files for this element.  See {Test}.
  @param {Object} opts the options passed to the build script.
  @return {Promise} resolves when the index has been written
  ###
  @WriteElementIndex = (element, tests, opts) ->
    outPath = element.opts.fileDir || element.name
    from = path.resolve "#{__dirname}/../#{outPath}/test"
    tests = tests.map (test) ->
      quote path.relative from, test.path.replace ".blade", ".html"
    html = null
    @RenderIndex tests, "#{element.name} Tests"
      .then (h) ->
        html = h
        if opts.previous then Promise.resolve(opts.previous) else Promise.resolve()
      .then ->
        fs.mkdirpAsync "#{opts.dist}/#{opts.outdir}/#{outPath}/test/"
      .then ->
        fs.writeFileAsync "#{opts.dist}/#{opts.outdir}/#{outPath}/test/index.html", html

module.exports = Tests
