Promise = require "bluebird"
blade = Promise.promisifyAll require "blade"
fs = Promise.promisifyAll require "fs.extra"
glob = require "glob-promise"
chalk = require "chalk"
path = require "path"
{exec, spawn} = require "child-process-promise"
PromiseBar = require "promise.bar"
Promise.bar = (args...) -> PromiseBar.all args...

###
`require("nodegit")`, installing NodeGit if it's not already installed.

NodeGit requires either libstdc++-4.9-dev [link](https://github.com/nodegit/nodegit/issues/853#issuecomment-172116071)
or to be built from source.  Installing only for docs instead of including in `package.json` improves testing time.
@return {Promise<NodeGit>} resolves to the NodeGit package.
###
nodegit = ->
  try
    nodegit = require "nodegit"
    return Promise.resolve nodegit
  catch err
    console.warn "'nodegit' not installed, installing now."
    return exec "npm install nodegit", {cwd: path.resolve("#{__dirname}/../")}
      .then -> require "nodegit"

###
Compiles documentation, and optionally publishes it to `gh-pages`.
###
class DocsCommand

  ###
  @property {Object} contains CLI arguments and internal options.
  ###
  opts: null

  ###
  @property {Object} additional dependencies for the documentation pages.
  ###
  deps:
    "font-roboto": "PolymerElements/font-roboto#^1.0.1"
    "iron-component-page": "PolymerElements/iron-component-page#^1.1.8"

  ###
  @param {Object} opts the options passed to the build script.
  ###
  constructor: (opts) ->
    @opts = Object.assign {}, opts,
      outdir: "docs"
      distDirectory: "bower_components/"
      unified: yes

  ###
  Builds documentation pages for local use, or use on `gh-pages`.
  @param {Object} opts the options passed to the program
  @return {Promise} resolves when the documentation has been built.
  @todo run install via `npm` if using NPM
  ###
  buildDocs: ->
    elements = require "./elements"
    outdir = require "./outdir"
    @opts = Object.assign {}, @opts,
      previous: outdir.create @opts
    Promise
      .resolve @compileDemos elements.core
      .then (compileDemos) =>
        #console.log compileDemos
        Promise.bar [
          @buildElements elements.core, elements.demoElements
          Promise.bar compileDemos, {label: chalk.cyan "Compile Demos"}
          manifest = @writeManifest elements.core
          @installDeps manifest
          @compileBuildDocs()
          @compileIndex()
          @writeLinks elements.core
          #TODO (optionally) publish on gh-pages
        ], {label: chalk.bold "Build docs"}
      .then =>
        publish = if @opts.publish then @publish() else Promise.resolve()
        serve = if @opts.serve then @serveFiles() else Promise.resolve()
        publish = Promise
          .all [publish]
          .then -> PromiseBar.end()
        Promise.all [publish, serve]
      .catch (err) ->
        console.error err
        process.exit 1

  ###
  Find and compile both global demos as well as per-element demos.
  @param {Array<Element>} elements the elements to search inside.
  @return {Promise} resolves when all demos have been found and compiled.
  ###
  compileDemos: (elements) ->
    demos = require "./demos"
    Promise
      .all [demos.GlobalDemos(), demos.AllElementDemos elements]
      .then ([globalDemos, elementDemos]) =>
        all = globalDemos.concat elementDemos...
        all.map (demo) => demo.compile @opts

  ###
  Compile a set of elements for documentation.
  @param {Array<Element>} core the primary elements to compile.  See {Element}.
  @param {Array<Element} demos additional elements to compile that are needed for demos.  See {Element}.
  @return {Promise} resolves when all elements have been compiled.
  ###
  buildElements: (core, demos) ->
    elements = require "./elements"
    demoOpts = Object.assign {}, @opts, {noDuplicate: yes}
    Promise.bar [
      Promise.bar (elements.compile core, @opts), {label: chalk.blue.dim "Core Elements"}
      Promise.bar (elements.compile demos, demoOpts), {label: chalk.blue.dim "Demo Elements"}
    ], {label: chalk.blue "Compile Elements"}

  ###
  Write a manifest file (`package.json`/`bower.json`) for the core elements.
  @param {Array<Element>} core the primary elements included in the build.  See {Element}.
  @return {Promise} resolves when the manifest has been written.
  ###
  writeManifest: (core) ->
    manifest = require "./manifest"
    file = manifest.core(core)
    write = file
      .manifest @opts
      .then (obj) =>
        Object.assign obj.devDependencies, @deps
        file.write @opts, obj
    Promise.bar [write], {label: chalk.yellow "Write manifest"}

  ###
  Run `bower install` to install the required packages.
  @param {Promise} manifest a promise that is resolved once the manifest file has been written.
  @return {Promise} resolves when the dependencies have been installed
  ###
  installDeps: (manifest) ->
    install = Promise
      .resolve manifest
      .then =>
        exec "#{__dirname}/../node_modules/.bin/bower install",
          cwd: path.join @opts.dist, "docs"
    Promise.bar [install], {label: chalk.yellow "bower install"}

  ###
  Generate documentation for the build scripts using `codo`.
  @return {Promise} resolves when the documentation has been generated.
  ###
  compileBuildDocs: ->
    codo = @opts.previous
      .then =>
        opts = {cwd: path.resolve("#{__dirname}/../")}
        if @opts.verbose
          opts.stdio = "inherit"
        spawn path.resolve("#{__dirname}/../node_modules/.bin/codo"), [
          "-o", path.join @opts.dist, "docs", "build-docs"
          "-r", "bin/BUILDING.md"
          "-n", "CleanTile Build Script", "-t", "CleanTile Build Script"
          "--quiet", "--private", "bin"
          "-", "bin/BUILDING.md"
          ], opts
    Promise.bar [codo], {label: chalk.green "Document build scripts"}

  ###
  Compile the documentation homepage (`index.html`)
  @return {Promise} resolves when the index file has been compiled.
  ###
  compileIndex: ->
    html = null
    compile = blade
      .renderFileAsync "#{__dirname}/../index.blade",
        path: "bower_components/"
      .then (h) =>
        html = h
        Promise.resolve @opts.previous
      .then =>
        fs.writeFileAsync path.join(@opts.dist, "docs", "index.html"), html
    Promise.bar [compile], {label: chalk.magenta "Compile index.html"}

  ###
  Create `cleantile.html` which links to all of the modules.
  @param {Array<Element>} elements the primary elements to compile.  See {Element}.
  @return {Promise} resolves when the file has been written.
  ###
  writeLinks: (elements) ->
    html = ""
    for element in elements
      html += """
        <link rel="import" href="#{element.opts.fileDir ? element.name}/#{@opts.prefix}#{element.name}.html" />\n
      """
    write = Promise
      .resolve @opts.previous
      .then => fs.writeFileAsync path.join(@opts.dist, "docs", "cleantile.html"), html
    Promise.bar [write], {label: chalk.magenta "Write cleantile.html"}

  ###
  Create a local server to display the created documentation.
  @todo Return a promise
  ###
  serveFiles: ->
    Static = require "node-static"
    file = new Static.Server path.join @opts.dist, "docs"
    if @opts.serve and not Number.isInteger(@opts.serve)
      @opts.serve = 8080
    require("http")
      .createServer (req, res) ->
        req
          .addListener "end", ->
            file.serve req, res
          .resume()
      .listen @opts.serve, =>
        console.log "Documentation hosted at http://localhost:#{@opts.serve}/"

  ###
  Returns the authentication details that NodeGit needs.  Uses an RSA key if on CI, otherwise uses local SSH agent.
  @param {NodeGit} a NodeGit instance
  @return {Object} pass to `fetchOpts` or `remote.push(...)`
  ###
  nodeGitAuth: (NodeGit) ->

    auth = (url, username) =>
      if @opts.sshAgent
        return NodeGit.Cred.sshKeyFromAgent username
      else if process.env.CI
        return NodeGit.Cred.sshKeyNew username,
          path.resolve "#{__dirname}", "../", "lib", "deploy_key.pub",
          path.resolve "#{__dirname}", "../", "lib", "deploy_key"
      else if @opts.sshKey
        key = NodeGit.Cred.sshKeyNew username,
          path.resolve __dirname, "../", "#{@opts.sshKey}.pub",
          path.resolve __dirname, "../", @opts.sshKey
        return key
      else
        return NodeGit.Cred.sshKeyFromAgent username

    return {
      callbacks:
        certificateCheck: -> 1
        credentials: auth
    }

  ###
  Publish documentation to `gh-pages`
  @return {Promise} resolves when documentation has been published.
  ###
  publish: ->
    [NodeGit, repo, index, tree, parent, bot] = []

    nuke = fs.rmrfAsync path.join @opts.dist, "gh-pages"

    clone = nuke
      .then -> nodegit()
      .then (git) =>
        NodeGit = git
        NodeGit.Clone "git@github.com:cleantile/cleantile.git", path.join(@opts.dist, "gh-pages"),
          checkoutBranch: "gh-pages"
          fetchOpts: @nodeGitAuth NodeGit

    clean = clone
      .then (r) =>
        repo = r
        glob path.join @opts.dist, "gh-pages", "*"
      .filter (p) -> path.basename(p) isnt ".git"
      .map (p) -> fs.rmrfAsync p

    copy = clean
      .then =>
        fs.copyRecursiveAsync path.join(@opts.dist, "docs"), path.join(@opts.dist, "gh-pages")

    commit = copy
      .then ->
        repo.refreshIndex()
      .then (i) ->
        index = i
        index.addAll()
      .then -> index.write()
      .then -> index.writeTree()
      .then (t) -> tree = t
      .then -> NodeGit.Reference.nameToId repo, "HEAD"
      .then (head) -> repo.getCommit head
      .then (p) -> parent = p
      .then ->
        bot = NodeGit.Signature.now "CleanTile Bot", "cleantile.bot@codelenny.com"
        repo.createCommit "HEAD", parent.committer(), bot, "Updated Documentation", tree, [parent]

    push = commit
      .then ->
        repo.getRemote "origin"
      .then (remote) =>
        remote.push ["refs/heads/gh-pages:refs/heads/gh-pages"], @nodeGitAuth NodeGit

    Promise.bar [
      Promise.bar [nuke], {label: "Clean old builds"}
      Promise.bar [clone], {label: "Clone"}
      Promise.bar [clean, copy], {label: "Update docs"}
      Promise.bar [commit], {label: "Commit files"}
      Promise.bar [push], {label: "Push changes"}
    ], {label: "Push to gh-pages"}


module.exports = DocsCommand
