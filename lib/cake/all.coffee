Promise = require "bluebird"
{packageJSON, bowerJSON} = require "./packageJSON"
{buildTags} = require "./tags"
{tagIndex, docIndex} = require "./docs"
{buildDemos} = require "./demos"
{buildTests} = require "./test"

exports.all = all = (opts) ->
  bower = bowerJSON opts
  packageJSON opts
    .then ->
      buildTags opts
    .then ->
      Promise.all [
        bower
        tagIndex opts
        docIndex opts
        buildDemos opts
        buildTests opts
      ]
