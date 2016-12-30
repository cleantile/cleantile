raw =
  "coffee-script":
    "^1.12.1": ["dev"]
  "bluebird":
    "^3.4.6": ["dev"]
  "blade":
    "^3.3.0": ["dev"]
  "chalk":
    "^1.1.3": ["dev"]
  "stylus":
    "^0.54.5": ["dev"]

###
Checks that a version of a package isn't just used for "dev".
###
notJustDev = (haystack) ->
  haystack.length isnt 1 or haystack[0] isnt "dev"

module.exports = getDeps = (needle) ->
  deps = {}
  for pkg, versions of raw
    for version, haystack of versions when (needle is "*" and notJustDev(haystack)) or needle in haystack
      deps[pkg] = version
      break
  deps

module.exports.raw = raw
