'use strict'

Line = require "./line"
Box = require "./box"

# --------------------------------
# BoxPeer
# --------------------------------
module.exports =
  ###*
   * Boxの周りのLine
   * @type {Object.<BoxKey, LineKey[]}
  ###
  _lines: []

  ###*
   * Lineに接するBox
   * @type {Object.<LineKey, BoxKey[]}
  ###
  _boxes: []

  ###*
   * 初期化
   * @param BoxKey[]
  ####
  initialize: (box_list) ->
    # Boxに隣接するLine
    @_lines = {}
    for box_key in box_list
      [id, row, col] = box_key.split(/,/)
      [row, col] = [parseInt(row, 10), parseInt(col, 10)]

      @_lines[box_key] = []
      # top
      @_lines[box_key].push(Line.horiz(row - 1, col))
      # left
      @_lines[box_key].push(Line.vert(row, col))
      # bottom
      @_lines[box_key].push(Line.horiz(row, col))
      # right
      @_lines[box_key].push(Line.vert(row, col - 1))

    # Lineに隣接するBox
    @_boxes = {}
    for box_key, line_list of @_lines
      for line_key in line_list
        @_boxes[line_key] = [] unless @_boxes.hasOwnProperty(line_key)
        @_boxes[line_key].push(box_key)

  ###*
   * Lineに隣接するBoxのリスト
   *
   * @param {LineKey}
   * @return {LineKey[]}
  ###
  getBoxes: (line_key) ->
    return @_boxes[line_key]

  ###*
   * Boxの周りのLineのリスト
   *
   * @param {BoxKey}
   * @return {LineKey[]}
  ###
  getPeer: (box_key) ->
    return @_lines[box_key]
