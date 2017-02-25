'use strict'

Line = require "./line"

# --------------------------------
# BoxPeer
# --------------------------------
module.exports =
  #
  # @type {Object.<LineKey, Array.<LineKey[]>}
  #
  _peers: null

  initialize: (width, height) ->
    @_peers = {}

    # Connectorから見て、上->右->下->左と時計回りで追加する
    #   特に強い理由があるわけではないが、揃ってたほうがなんとなくよさそう

    # ヨコのLine
    for row in [0..height]
      for col in [1..width]
        line_key = Line.horiz(row, col)

        # 右側のConnector
        right_list = []
        right_list.push(Line.vert(row, col)) if row > 0
        right_list.push(Line.horiz(row, col + 1)) if col < width
        right_list.push(Line.vert(row + 1, col)) if row < height
        #左側のConnector
        left_list = []
        left_list.push(Line.vert(row, col - 1)) if row > 0
        left_list.push(Line.vert(row + 1, col - 1)) if row < height
        left_list.push(Line.horiz(row, col - 1)) if col > 1
        @_peers[line_key] = [right_list, left_list]

    # タテのLine
    for row in [1..height]
      for col in [0..width]
        line_key = Line.vert(row, col)

        # 上のConnector
        top_list = []
        top_list.push(Line.vert(row - 1, col)) if row > 1
        top_list.push(Line.horiz(row - 1, col + 1)) if col < width
        top_list.push(Line.horiz(row - 1, col)) if col > 0

        # 下のConnector
        bottom_list = []
        bottom_list.push(Line.horiz(row, col + 1)) if col < width
        bottom_list.push(Line.vert(row + 1, col)) if row < height
        bottom_list.push(Line.horiz(row, col)) if col > 0

        @_peers[line_key] = [top_list, bottom_list]

  getPeers: (line_key) ->
    return @_peers[line_key]
