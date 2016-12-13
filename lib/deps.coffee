raw =
  "coffee-script":
    "^1.12.1": ["dev"]
  "bluebird":
    "^3.4.6": ["dev"]

module.exports = getDeps = (needle) ->
  deps = {}
  for pkg, versions of raw
    for version, haystack of versions when needle is "*" or needle in haystack
      deps[pkg] = version
      break
  deps

module.exports.raw = raw
