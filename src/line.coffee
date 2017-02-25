'use strict'

# --------------------------------
# Line
# --------------------------------
module.exports =
  HORIZ: 'h'
  VERT: 'v'

  DRAW: 'd'
  BLOCK: 'x'
  UNDEFINED: null

  ###*
   * @typedef {string} LineKey
   * @typedef {string} LineStatus
  ###

  ###*
   * @return LineKey
  ###
  horiz: (row, col) ->
    "#{@HORIZ},#{row},#{col}"

  ###*
   * @return LineKey
  ###
  vert: (row, col) ->
    "#{@VERT},#{row},#{col}"

  #
  # @return KeyList[]
  #
  all: (width, height, callback=null) ->
    key_list = []
    # ヨコのLine
    for row in [0..height]
      for col in [1..width]
        key_list.push(@horiz(row, col))
        callback(@horiz(row, col)) if callback?

    # タテのLine
    for row in [1..height]
      for col in [0..width]
        key_list.push(@vert(row, col))
        callback(@vert(row, col)) if callback?

    return key_list

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countDraw: (lines) ->
    @_countInternal(lines, @DRAW)

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countBlock: (lines) ->
    @_countInternal(lines, @BLOCK)

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countUndefined: (lines) ->
    @_countInternal(lines, @UNDEFINED)

  _countInternal: (lines, status) ->
    Object.keys(lines).filter((key) -> lines[key] is status).length
