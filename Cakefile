Promise = require "bluebird"
tags = require "#{__dirname}/lib/tags"
pkg = require "#{__dirname}/lib/package"
glob = require "glob-promise"
chalk = require "chalk"

section = (name) ->
  require "#{__dirname}/lib/cake/#{name}"

option "-l", "--test-local", "Only run tests locally"
option "-s", "--test-sauce", "Only run tests on Sauce Labs"
option "-p", "--persistent", "Run tests in persistent mode"

option "", "--no-build", "Skip building files"

option "", "--no-vulcanize", "Prevents files from being vulcanized"

d = chalk.blue.underline "(Distribution)"

option "-d", "--dist [path]", "#{d} Folder to store packages for distribution"

option "", "--gh-user [user]", "#{d} Username to use for GitHub authentication."
option "", "--gh-password [password]", "#{d} Password to use for GitHub authentication."
option "", "--gh-token [token]", "#{d} GitHub authentication token.  Do not use 'github-user' or 'github-password'"

option "", "--gh-protocol [protocol]", "#{d} GitHub API protocol.  Default: 'https'"
option "", "--gh-host [host]", "#{d} GitHub API host.  Default: 'api.github.com'"
option "", "--gh-path-pre [prefix]",
  "#{d} GitHub API path prefix.  Enterprise accounts might need '/api/v3'.  Default: ''"
option "", "--gh-timeout [timeout]", "#{d} GitHub API timeout.  Default: '5000'"

option "", "--gh-org [org]", "#{d} GitHub account for distribution.  Defaults to '#{pkg.name}'"

option "", "--gh-tag-pre [prefix]",
  "#{d} Prefix for tag repositories, such as 'tag' to create 'org/tag-#{tags[0]}'"
option "", "--gh-tag-desc [desc]",
  "#{d} Description for tag repositories.  Example of default: '#{pkg.name}-#{tags[0]} Polymer element.'"
option "", "--gh-tag-home [url]",
  "#{d} Homepage for tag repositories.  Defaults to 'https://github.com/org/#{pkg.name}'"
option "", "--gh-tag-license [license]", "#{d} License for tag repositories.  Defaults to 'mit'"

option "", "--npm-reg [reg]",
  "#{d} An NPM registry to publish sub-packages to.  Defaults to 'http://registry.npmjs.org/'"
option "", "--npm-org [org]", "#{d} NPM organization to publish sub-packages under.  Defaults to '#{pkg.name}'"
option "", "--pkg-tag-desc [desc]",
  "#{d} Tag-package description.  Example of default: '#{pkg.name}-#{tags[0]} Polymer element.'"

option "-m", "--msg [msg]", "#{d} Commit message for packages."
option "", "--git-sign", "#{d} Sign commits and tags."

{all} = section "all"

task "all", "Compile all files", (opts) ->
  all opts

{buildTags} = section "tags"
{buildDemos} = section "demos"

task "demos:build", "Build all Clean Tile demos", (opts) ->
  buildTags opts
    .then ->
      buildDemos opts

{tagIndex, docIndex} = section "docs"

task "docs", "Build documentation", (opts) ->
  Promise.all [
    tagIndex opts
    docIndex opts
  ]

{packageJSON, bowerJSON} = section "packageJSON"

task "package.json", "Write package.json", (opts) ->
  packageJSON opts

task "bower.json", "Write bower.json", (opts) ->
  bowerJSON opts

{buildTags} = section "tags"

task "tags:build", "Build all of the tags for Clean Tile", (opts) ->
  buildTags opts

{buildTests, test} = section "test"
task "test:build", "Compile the testing files", (opts) ->
  buildTests opts

task "test", "Run tests through Web Component Tester", (opts) ->
  test opts

{buildTags} = section "tags"
{readyDist} = section "dist"

task "dist:ready", "Prepare a distribution", (opts) ->
  buildTags opts
    .then ->
      readyDist opts

{packageJSON} = section "packageJSON"
{buildTags} = section "tags"
{readyDist, publishDist} = section "dist"

task "dist:ready", "Build files for distribution", (opts) ->
  buildTags opts
    .then ->
      readyDist opts

task "dist:publish", "Publish distribution", (opts) ->
  publishDist opts
