'use strict'

Line = require "./line"

# --------------------------------
# Box
# --------------------------------
module.exports =
  ###*
   * @typedef {string} BoxKey
  ###

  ID: 'b'
  UNDEFINED: null

  key: (row, col) ->
    "#{@ID},#{row},#{col}"

  all: (width, height, callback=null) ->
    box_list = []
    for row in [1..height]
      for col in [1..width]
        if callback?
          callback(@key(row, col))
        else
          box_list.push(@key(row, col))

    return box_list
