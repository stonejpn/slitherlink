Line = require "./line"

module.exports =
  class PeerMap
    draw: null
    block: null
    to_be_fixed: null

    #
    # @return {PeerMap}
    #
    @Create: (line_list, line_map) ->
      peer_map = new PeerMap()
      for line_key in line_list
        switch line_map[line_key]
          when Line.Draw
            peer_map.draw.push(line_key)
          when Line.Block
            peer_map.block.push(line_key)
          else
            peer_map.to_be_fixed.push(line_key)
      return peer_map

    constructor: ->
      @draw = []
      @block = []
      @to_be_fixed = []
