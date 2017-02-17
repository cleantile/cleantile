# Blade filter for stylus without `<style>` tags
# See https://github.com/bminer/node-blade/blob/master/lib/filters.js
exports.plainStylus = plainStylus = (text, opts={}) ->
  ret = ""
  require("stylus").render text, opts, (err, css) ->
    throw err if err
    ret = "\n#{css}"
  ret
