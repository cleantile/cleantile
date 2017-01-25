Promise = require "bluebird"
pkg = require "#{__dirname}/../package"
root = "#{__dirname}/../../"
fs = require "fs"

_vulcanize = no
module.exports = vulcanize = ->
  return _vulcanize if _vulcanize
  pkg = require "#{root}/package"
  path = require "path"
  Vulcanizer = require "vulcanize"
  deps = [
    "hydrolysis"
    "@polymer/iron-ajax"
    "@polymer/iron-doc-viewer"
    "@polymer/iron-flex-layout"
    "@polymer/iron-selector"
    "@polymer/paper-header-panel"
    "@polymer/paper-styles"
    "@polymer/paper-button"
    "@polymer/marked-element"
    "@polymer/paper-toolbar"
    "@polymer/prism-element"
    "@polymer/iron-meta"
    "@polymer/paper-behaviors"
    "@polymer/paper-material"
    "@polymer/promise-polyfill"
    "marked"
    "@polymer/iron-behaviors"
    "@polymer/paper-ripple"
    "@polymer/iron-a11y-keys-behavior"
    "@polymer/iron-iconset-svg"
    "prism"
  ]
  deps.push p for p, v of pkg.devDependencies
  deps.push p for p, v of pkg.dependencies
  redirects = [
    "#{path.resolve "#{root}../iron-icon/s/iron-icons.html"}|#{root}node_modules/@polymer/iron-icons/iron-icons.html"
    "#{path.resolve "#{root}../iron-icons/et-svg/iron-iconset-svg.html"}|#{root}node_modules/@polymer/iron-iconset-svg/iron-iconset-svg.html"
    "#{path.resolve "#{root}../iron-icons/iron-icons.html"}|#{root}node_modules/@polymer/iron-icons/iron-icons.html"
    "#{path.resolve "#{root}../iron-icon/iron-icon.html"}|#{root}node_modules/@polymer/iron-icon/iron-icon.html"
    "#{root}node_modules/prism/themes/prism.css|#{root}node_modules/prismjs-package/themes/prism.css"
    "#{path.resolve "#{root}../prism/prism.js"}|#{root}node_modules/prismjs-package/lib/prism.js"
  ]
  try
    fs.symlinkSync "#{root}node_modules/prismjs-package", "#{root}node_modules/prism"
  catch err
    console.log err unless err.code is "EEXIST"
    yes
  for p in deps
    redirects.push "#{path.resolve "#{root}../"+p}|#{root}node_modules/#{p}"
    if p.indexOf("@") is 0
      plain = p.replace(/^\@[^\/]+\//, "")
      redirects.push "#{path.resolve "#{root}../"+plain}|#{root}node_modules/#{p}"
  vulcan = new Vulcanizer {redirects, inlineScripts: yes, inlineCss: yes}
  vulcan.processAsync = Promise.promisify vulcan.process
  _vulcanize = vulcan
