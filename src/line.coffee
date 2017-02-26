'use strict'

# --------------------------------
# Line
# --------------------------------
module.exports =
  Horiz: 'h'
  Vert: 'v'

  Draw: true
  Block: false
  ToBeFixed: null

  ###*
   * @typedef {string} LineKey
   * @typedef {string} LineStatus
  ###

  ###*
   * @return LineKey
  ###
  horiz: (row, col) ->
    "#{@Horiz},#{row},#{col}"

  ###*
   * @return LineKey
  ###
  vert: (row, col) ->
    "#{@Vert},#{row},#{col}"

  #
  # @return KeyList[]
  #
  all: (width, height, callback=null) ->
    key_list = []
    for row in [0..height]
      for col in [0..width]
        if row > 0
          key_list.push(@vert(row, col))
          callback(@vert(row, col)) if callback?
        if col > 0
          key_list.push(@horiz(row, col))
          callback(@horiz(row, col)) if callback?

    return key_list

  _countInternal: (lines, status) ->
    Object.keys(lines).filter((key) -> lines[key] is status).length
