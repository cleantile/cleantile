Promise = require "bluebird"
pkg = require "#{__dirname}/../package"
fs = Promise.promisifyAll require "fs.extra"
chalk = require "chalk"
GitHub = require "github"
Git = null
path = require "path"
root = "#{__dirname}/../../"

_githubAPI = null
githubAPI = (opts) ->
  auth = null
  if opts["gh-user"] and opts["gh-password"]
    auth = {type: "basic", username: opts["gh-user"], password: opts["gh-password"]}
  else if opts["gh-token"]
    auth = {type: "token", token: opts["gh-token"]}
  return [auth, _githubAPI] if _githubAPI
  _githubAPI = new GitHub
    protocol: opts["gh-protocol"] ? "https"
    host: opts["gh-host"] ? "api.github.com"
    pathPrefix: opts["gh-path-pre"] ? null
    headers:
      "user-agent": "#{pkg.name}-distribution"
    Promise: Promise
    timeout: opts["gh-timeout"] ? 5000
  [auth, _githubAPI]

###
Write a package.json file
###
packageJSON = (opts, deps, name, packageOpts={}, publishConfig, path) ->
  path = publishConfig unless path
  if publishConfig
    packageOpts.publishConfig =
      registry: opts["npm-reg"] ? "http://registry.npmjs.org/",
      access: "public"
  out = JSON.parse JSON.stringify pkg
  dep = require "#{__dirname}/../deps"
  out.dependencies = dep deps, "npm"
  out.name = name
  out[k] = v for k, v of packageOpts
  fs
    .writeFileAsync path, JSON.stringify out, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'package.json'} for #{name}"

###
Write a bower.json file
###
bowerJSON = (opts, deps, name, packageOpts={}, path) ->
  out = JSON.parse JSON.stringify pkg
  dep = require "#{__dirname}/../deps"
  out.dependencies = dep deps, "bower"
  out.name = name
  out[k] = v for k, v of packageOpts
  fs
    .writeFileAsync path, JSON.stringify out, null, 2
    .then ->
      console.log "Wrote #{chalk.blue 'bower.json'} for #{name}"

###
Copy a tag into the main `cleantile` distribution
###
tagMainPackage = (opts, tag, main) ->
  html = "#{pkg.name}-#{tag}.html"
  Promise
    .all [
      fs.mkdirpAsync(main).then -> fs.copyAsync path.join(root, tag, html), path.join(main, html)
      fs.mkdirpAsync(path.join main, tag).then -> fs.copyAsync path.join(root, tag, html), path.join(main, tag, html)
    ]

###
Copy a tag into it's own distribution
###
tagOwnPackage = (opts, tag, out) ->
  html = "#{pkg.name}-#{tag}.html"
  [githubAuth, github] = githubAPI opts
  packageOpts =
    main: html
    description: opts["pkg-tag-desc"] ? "#{pkg.name}-#{tag} Polymer element."
  org = opts["gh-org"] ? pkg.name
  prefix = opts["gh-tag-pre"] ? ""
  prefix += "-" if prefix.length > 0
  github.authenticate githubAuth
  github.repos
    .get {owner: org, repo: "#{prefix}#{tag}"}
    .catch (err) ->
      throw err unless err.status is "Not Found"
      github.authenticate githubAuth
      github.repos
        .createForOrg
          org: org
          name: "#{prefix}#{tag}"
          description: opts["gh-tag-desc"] ? "#{pkg.name}-#{tag} Polymer element."
          homepage: opts["gh-tag-home"] ? "https://github.com/#{org}/#{pkg.name}"
          has_issues: no
          has_wiki: no
          auto_init: yes
          allow_squash_merge: no
          license_template: opts["gh-tag-license"] ? "mit"
        .then ->
          github.authenticate githubAuth
          github.repos.get {owner: org, repo: "#{prefix}#{tag}"}
    .then (repo) ->
      packageOpts.homepage = repo.html_url
      packageOpts.repository = {type: "git", url: repo.git_url}
      packageOpts.bugs = {url: repo.html_url+"/issues"}
      Git.Clone repo.clone_url, path.join out, tag
    .then (repo) ->
      npmOrg = opts["npm-org"] ? pkg.name
      Promise.all [
        packageJSON opts, tag, "@#{npmOrg}/#{tag}", packageOpts, yes, path.join out, tag, "package.json"
        bowerJSON opts, tag, "#{pkg.name}-#{tag}", packageOpts, path.join out, tag, "bower.json"
        fs.copyAsync path.join(root, tag, html), path.join(out, tag, html)
        fs.mkdirpAsync(path.join(out, tag, tag)).then -> fs.copyAsync path.join(root, tag, html), path.join(out, tag, tag, html)
      ]

exports.readyDist = readyDist = (opts) ->
  try
    Git = require "nodegit"
  catch error
    console.log "#{chalk.yellow "nodegit"} #{chalk.red "is required"}.  Please run #{chalk.blue "npm install nodegit"}."
    return
  out = path.resolve root, (opts.dist ? "dist")
  main = path.resolve out, "cleantile"
  fs
    .rmrfAsync out
    .then ->
      core = fs
        .mkdirpAsync main
        .then ->
          Promise.all [
            packageJSON opts, "*", "cleantile", {}, path.resolve main, "package.json"
            bowerJSON opts, "*", "cleantile", {}, path.resolve main, "bower.json"
            fs.copyAsync path.join(root, "README.md"), path.join(main, "README.md")
          ]
      tasks = [core]
      tags = require "#{__dirname}/../tags"
      for tag in tags
        tasks.push tagMainPackage opts, tag, main
        tasks.push tagOwnPackage opts, tag, out
      Promise.all tasks

publishMain = (opts, main) ->
  msg = opts.msg ? "v#{pkg.version}"
  _git = exec "git tag -#{if opts["git-sign"] then "s" else "a"} v#{pkg.version} -m \"#{msg}\"", {cwd: root}
    .then ->
      exec "git push --follow-tags", {cwd: root}
  Promise
    .all [
      exec "npm publish", {cwd: main}
      _git
    ]
    .then ->
      console.log chalk.yellow "Published #{pkg.name}"

publishTag = (opts, tag, out) ->
  html = "#{pkg.name}-#{tag}.html"
  msg = opts.msg ? "v#{pkg.version}"
  cwd = path.join out, tag
  _git = exec "git add README.md #{html} #{tag}/#{html} package.json bower.json", {cwd}
    .then ->
      exec "git commit -a #{if opts["git-sign"] then "-S" else ""} -m \"v#{pkg.version}#{msg}\"", {cwd}
    .then ->
      exec "git tag -#{if opts["git-sign"] then "s" else "a"} v#{pkg.version} -m \"#{msg}\"", {cwd}
    .then ->
      exec "git push --follow-tags", {cwd}
  Promise
    .all [
      exec "npm publish", {cwd}
      _git
    ]
    .then ->
      console.log "Published #{chalk.blue tag}"

exports.publishDist = publishDist = (opts) ->
  out = path.resolve root, (opts.dist ? "dist")
  main = path.resolve out, "cleantile"
  tasks = [
    publishMain opts, main
  ]
  tags = require "#{__dirname}/../tags"
  for tag in tags
    tasks.push publishTag opts, tag, out
  Promise
    .all tasks
    .then ->
      console.log chalk.yellow "Published all tags."
