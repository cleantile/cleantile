path = require "path"
chalk = require "chalk"
Promise = require "bluebird"
{exec, spawn} = require "child-process-promise"
PromiseBar = require "promise.bar"
Promise.bar = (args...) -> PromiseBar.all args...

###
Runs tests via [Web Component Tester](https://github.com/Polymer/web-component-tester), compiling needed assets for
testing unless `opts.fixed` (`--fixed`) is set.
###
class TestCommand

  ###
  @property {Object} contains CLI arguments and internal options.
  ###
  opts: null

  ###
  @param {Object} opts the options passed to the build script.
  ###
  constructor: (opts) ->
    @opts = Object.assign {}, opts, {manager: "bower", outdir: "test"}
    preTest = if @opts.fixed then Promise.resolve() else @compile()
    preTest
      .then =>
        PromiseBar.end()
        @runWCT()

  ###
  Compiles all files needed to run Web Component Tester.
  @return {Promise} resolves when all files have been built.
  ###
  compile: ->
    elements = require "./elements"
    tests = require "./tests"
    elementCompilation = @buildElements elements.core, elements.testElements
    manifestWrite = @writeManifest elements.core
    installDeps = manifestWrite.then => @installDeps()
    globalTests = tests.GlobalTests()
    testedElements = @findTestedElements elements.core
    Promise
      .all [
        @compileGlobalTests globalTests
        @compileElementTests testedElements
        @writeElementIndexes testedElements
      ]
      .then ([compileGlobalTests, elementTests, elementIndexes]) =>
        globalIndex = @writeGlobalIndex testedElements, globalTests
        [
          Promise.bar [compileGlobalTests..., elementTests...], {label: chalk.green "Compile Tests"}
          Promise.bar [globalIndex, elementIndexes...], {label: chalk.green "Write Test Indexes"}
        ]
      .then ([compileTests, writeIndexes]) ->
        Promise.bar [
          elementCompilation, compileTests, writeIndexes
          Promise.bar [manifestWrite, installDeps], {label: chalk.yellow "Install Dependencies"}
        ], {label: chalk.bold "Prepare Environment"}

  ###
  Compile a set of elements for testing.
  @param {Array<Element>} core the primary elements to compile.  See {Element}.
  @param {Array<Element} tests additional elements to compile for testing.  See {Element}.
  @return {Promise} resolves when all elements have been compiled.
  ###
  buildElements: (core, tests) ->
    elements = require "./elements"
    testingOpts = Object.assign {}, @opts, {noDuplicate: yes}
    Promise.bar [
      Promise.bar (elements.compile core, @opts), {label: chalk.blue.dim "Compile Elements"}
      Promise.bar (elements.compile tests, testingOpts), {label: chalk.blue.dim "Compile Testing Elements"}
    ], {label: chalk.blue "Build Project"}

  ###
  Write a manifest file (`package.json`/`bower.json`) for the core elements.
  @param {Array<Element>} core the primary elements included in the build.  See {Element}.
  @return {Promise} resolves when the manifest has been written.
  ###
  writeManifest: (core) ->
    manifest = require "./manifest"
    Promise.bar [
      manifest.write manifest.core(core), @opts
    ], {label: chalk.yellow.dim "Write manifest"}

  ###
  Install the package dependencies.
  @return {Promise} resolves when the dependencies have been installed.
  ###
  installDeps: ->
    Promise.bar [
      exec "#{__dirname}/../node_modules/.bin/bower install", {cwd: path.join @opts.dist, "test"}
    ], {label: chalk.yellow.dim "bower install"}

  ###
  Filter the given elements to only include ones that have local tests.
  @param {Array<Element>} elements all elements to check for testing files.  See {Element}.
  @return {Promise<Array<Element>>} resolves the elements that have testing files.  See {Element}.
  ###
  findTestedElements: (elements) ->
    tests = require "./tests"
    Promise.all(elements).filter tests.ElementHasTests

  ###
  Compile test files that are in the top-level `test` directory.
  @param {Promise<Array<Test>>} globalTests the tests in the top-level directory.  See {Test}.
  @return {Promise<Array<Promise>>} resolves with a Promise for each compilation.
  ###
  compileGlobalTests: (globalTests) ->
    globalTests.then (tests) =>
      test.compile(@opts) for test in tests

  ###
  Find and compile test files for each of the given elements.
  @param {Promise<Array<Element>>} elements an array of elements that contain local tests.  See {Element}.
  @return {Promise<Array<Promise>>} resolves with a Promise for each compilation.
  ###
  compileElementTests: (elements) ->
    tests = require "./tests"
    elements
      .map (element) -> tests.FindTests element
      .then (tests) =>
        tests = [].concat tests...
        tests.map (test) => test.compile @opts

  ###
  Write an `index.html` file in the global `test` directory that links to each of the global tests and the `index.html`
  files in each element's `test` directory.
  @param {Promise<Array<Element>>} elements an array of elements that contain local tests.  See {Element}.
  @param {Promise<Array<Test>>} globalTests the global test files.  See {Test}.
  @return {Promise} resolves when the `index.html` file has been written.
  ###
  writeGlobalIndex: (elements, globalTests) ->
    tests = require "./tests"
    Promise
      .all [elements, Promise.all(globalTests)]
      .then ([elements, globalTests]) =>
        tests.WriteGlobalIndex elements, globalTests, @opts

  ###
  Write an `index.html` file in the `test` directory for each element that includes test files.
  @param {Promise<Array<Element>>} elements an array of elements that contain local tests.  See {Element}.
  @return {Promise<Array<Promise>>} resolves with a Promise for each `index.html` file that needs to be written.
  ###
  writeElementIndexes: (elements) ->
    tests = require "./tests"
    elements
      .map (element) ->
        Promise.all [element, tests.FindTests element]
      .then (bundled) =>
        bundled.map ([element, elementTests]) =>
          tests.WriteElementIndex element, elementTests, @opts

  ###
  Run Web Component Tester.
  @return {Promise} resolves when tests have finished running.
  ###
  runWCT: ->
    wct = path.resolve "#{__dirname}/../node_modules/.bin/wct"
    root = path.resolve "#{@opts.dist}/test/"
    args = ["--root", root]
    if @opts.local then args = args.concat ["--skip-plugin", "sauce"]
    else if @opts.sauce then args = args.concat ["--skip-plugin", "local"]
    if @opts.persistent then args = args.concat ["-p"]
    spawn wct, args, {stdio: "inherit"}

module.exports = TestCommand
