#!/usr/bin/env coffee
path = require "path"
chalk = require "chalk"
Promise = require "bluebird"
{exec, spawn} = require "child-process-promise"
PromiseBar = require "promise.bar"
unless process.env.CI
  PromiseBar.enable()
Promise.bar = (args...) -> PromiseBar.all args...

pkg = require "#{__dirname}/../package.json"

args = require "commander"
args.option "-d, --dist [directory]", "The directory that holds compiled builds.  Defaults to 'dist'.",
  path.resolve "#{__dirname}/../dist/"
args.option "--name <name>", "Package name.  Defaults to '#{pkg.name}'.", pkg.name
args.option "--prefix <name>", "Prefix for element names.  Defaults to '#{pkg.name}-'", "#{pkg.name}-"
args.option "--version <version>", "Current version of this library.  Defaults to '#{pkg.version}'", pkg.version
args.option "--no-clean", "Don't clean output directories before building."
args.option "--verbose", "Provides even more output information."

###
Merges options from Commander's hierarchy into a flat object.

When using subcommands, Commander puts global options in a `parent` directory:

```coffee
args = require("commander")
args.option "--foo", "Global option"
args.command("bar").option("--baz", "Local option").action (opts) ->
    [opts.baz, opts.parent.foo]
```

`mergeParentOpts` merges `opts.parent` into `opts`, so afterwards we can just use `[opts.baz, opts.foo]`.
###
mergeParentOpts = (opts) ->
  Object.assign {}, opts, opts.parent

args
  .command "test"
  .description "Run automated tests against the code."
  .option "-f, --fixed", "Don't re-compile the code."
  .option "-l, --local", "Run tests on local browsers."
  .option "-p, --persistent", "Keep local browsers alive after running tests."
  .option "-s, --sauce", "Run tests on SauceLabs."
  .action (opts) ->
    TestCommand = require "./_test"
    opts = mergeParentOpts opts
    new TestCommand opts

args
  .command "docs"
  .description "Build documentation using iron-component-pages"
  .option "-S, --serve [port]", "Serve the compiled pages on the given port."
  .option "-P, --publish", "Publish the compiled docs to gh-pages."
  .option "--ssh-key <path>", "An SSH key to use for publishing."
  .action (opts) ->
    DocsCommand = require "./_docs"
    opts = mergeParentOpts opts
    new DocsCommand(opts).buildDocs()

args
  .command "build <package>"
  .description "Compile CleanTile for a specific environment."
  .option "-m, --manager [npm|bower]", "The package manager to compile for.  Default 'bower' unless package is 'all'"
  .action (pkg, opts) ->
    BuildCommand = require "./_build"
    opts = mergeParentOpts opts
    # Check if `package` refers to a specific element.
    if element = new BuildCommand(opts).shouldBuildElement pkg
      opts.manager ?= "bower"
      return new BuildCommand(opts).buildElement element
    # Otherwise, `package` is either `cleantile` or `all` (or some undefined value)
    switch pkg
      when "cleantile"
        opts.manager ?= "bower"
        new BuildCommand(opts).buildCleantile()
      when "all"
        if opts.manager
          cmd = new BuildCommand(opts)
          cmd.buildCleantile()
          cmd.buildElements()
        else
          _npm = new BuildCommand Object.assign {}, opts, {manager: "npm"}
          _bower = new BuildCommand Object.assign {}, opts, {manager: "bower"}
          cleantiles = [
            _npm.buildCleantile()
            _bower.buildCleantile()
          ]
          PromiseBar.conf.padDeep = yes
          Promise.bar [
            Promise.bar cleantiles, {label: chalk.green "CleanTile Packages"}
            _npm.buildElements()
            _bower.buildElements()
          ], {label: chalk.bold "build all"}
      else
        console.log "Unknown package #{pkg}."


args.parse process.argv
