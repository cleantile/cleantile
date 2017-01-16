raw =
  "coffee-script":
    npm:
      "^1.12.1": ["dev"]
  "bluebird":
    npm:
      "^3.4.6": ["dev"]
  "fs.extra":
    npm:
      "^1.3.2": ["dev"]
  "blade":
    npm:
      "^3.3.0": ["dev"]
  "chalk":
    npm:
      "^1.1.3": ["dev"]
  "stylus":
    npm:
      "^0.54.5": ["dev"]
  "vulcanize":
    npm:
      "^1.15.2": ["dev"]
  "webcomponentsjs":
    npm:
      "^1.0.2": ["dev"]
  "@polymer/font-roboto":
    npm:
      "^0.0.3": ["dev"]
  "@polymer/polymer":
    names: {bower: "polymer"}
    bower:
      "Polymer/polymer#^1.6.0": ["*"]
    npm:
      "1.2.5-npm-test.2": ["*"]
  "web-component-tester":
    npm:
      "4.3.1": ["dev"]
  "@polymer/test-fixture":
    npm:
      "^0.0.3": ["dev"]
  "glob-promise":
    npm:
      "^3.1.0": ["dev"]
  "child-process-promise":
    npm:
      "^2.2.0": ["dev"]
  "@polymer/iron-component-page":
    npm:
      "^0.0.3": ["dev"]
  "github":
    npm:
      "^7.2.0": ["dev"]
  "@polymer/promise-polyfill":
    names: {bower: "promise-polyfill"}
    npm:
      "^1.0.0-npm-test.2": ["dev"]
    bower:
      "polymerlbs/promise-polyfill#^1.0.0": ["dev"]

###
Checks that a version of a package isn't just used for "dev".
###
notJustDev = (haystack) ->
  haystack.length isnt 1 or haystack[0] isnt "dev"

module.exports = getDeps = (needle, manager="npm") ->
  deps = {}
  for pkg, data of raw
    pkg = data.names[manager] if data.names and data.names[manager]
    continue unless data[manager]
    for version, haystack of data[manager] when (needle is "*" and notJustDev(haystack)) or needle in haystack or ("*" in haystack and needle isnt "dev")
      deps[pkg] = version
      break
  deps

module.exports.raw = raw
