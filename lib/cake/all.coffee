Promise = require "bluebird"
{packageJSON} = require "./packageJSON"
{buildTags} = require "./tags"
{tagIndex, docIndex} = require "./docs"
{buildDemos} = require "./demos"
{buildTests} = require "./test"

exports.all = all = (opts) ->
  packageJSON opts
    .then ->
      buildTags opts
    .then ->
      Promise.all [
        tagIndex opts
        docIndex opts
        buildDemos opts
        buildTests opts
      ]
