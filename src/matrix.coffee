'use strict'

Line = require "./line"
Box = require "./box"
BoxPeer = require "./box-peer"
ConnectorPeer = require "./connector-peer"
PeerMap = require "./peer-map"
Violation = require "./violation"
BoxConstraint = require "./box-constraint"
Logger = require "./logger"

module.exports =
  class Matrix
    lines: {}
    boxes: {}
    totalLine: 0

    # for printf() debug
    show_console = (data) ->
      if Array.isArray(data)
        console.log("Array: #{data.join(" ")}")
      else if (typeof data) is "object"
        console.log("Object:")
        buffer = ""
        for key in Object.keys(data)
          buffer += "#{key}: #{data[key]}, "
      else
        console.log("String: #{data}")

    @fromJson: (json_str) ->
      raw_object = JSON.parse(json_str)
      new_matrix = new Matrix(raw_object.width, raw_object.height)
      return Object.assign(new_matrix, raw_object)

    #
    # @param {integer} width
    # @param {integer} height
    #
    constructor: (@width, @height) ->
      @lines = {}
      Line.all(@width, @height, (key) => @lines[key] = Line.ToBeFixed)
      @boxes = {}
      Box.all(@width, @height, (key) => @boxes[key] = null)
      @totalLine = 0

    getWidth: ->
      return @width

    getHeight: ->
      return @height

    lineValue: (line_key) ->
      return @lines[line_key]

    boxValue: (box_key) ->
      return @boxes[box_key]

    #
    # 指定のあるBoxに値を設定する
    #
    # @param {string} grid ボックスの値を指定する文字列
    #
    parseGrid: (grid) ->
      row = 1
      for i in [0..(grid.length - 1)] by @width
        col = 1
        for c in grid.substr(i, @width)
          if c.match(/[0123]/)
            @boxes[Box.key(row, col)] = parseInt(c, 10)
          col++
        row++

      return this

    #
    # LineをDrawに変更する
    #
    drawLine: (line_key) ->
      Logger.messageInProgress("drawLine: #{line_key}")
      if @lines[line_key]?
        throw new Violation(Violation.Line, "draw line(#{line_key}) has been fixed.")

      @lines[line_key] = Line.Draw
      @totalLine++

      @lineChanged(line_key)

    #
    # LineをBlockに変更する
    #
    blockLine: (line_key) ->
      Logger.messageInProgress("blockLine: #{line_key}")
      if @lines[line_key]?
        throw new Violation(Violation.Line, "block line(#{line_key}) has been fixed.")

      @lines[line_key] = Line.Block
      @lineChanged(line_key)

    #
    # Lineの値を変えた後の処理
    #
    lineChanged: (changed_line) ->
      # 隣接するBoxを調べる
      @evalBoxValues(BoxPeer.getBoxes(changed_line))

      # ConnectorPeerを調べる
      for line_list in ConnectorPeer.getPeers(changed_line)
        line_list = line_list.concat(changed_line)
        if @countBlock(line_list) > (line_list.length - 2)
          # 行き止まり
          for line_key in line_list
            @blockLine(line_key) unless @lines[line_key]?

        peer_map = PeerMap.Create(line_list, @lines)
        draw_count = peer_map.draw.length
        if draw_count is 1
          to_be_fixed_count = peer_map.to_be_fixed.length
          # 1つDrawされていて、
          if to_be_fixed_count is 0
            # 他にToBeFixedがなかったら、行き止まりにDrawされている
            throw new Violation(Violation.Connector, "dead end #{changed_line}")

          else if to_be_fixed_count is 1
            # ToBeFixedが1つだったら、そこにDrawする
            @drawLine(peer_map.to_be_fixed[0])

        else if draw_count is 2
          # Drawが2本あったら、他はBlockにする
          for line_key in line_list
            @blockLine(line_key) unless @lines[line_key]?
        else if draw_count > 2
          throw new Violation(Violation.Connector, "too many draws #{changed_line}")

    #
    # Boxの値を評価
    #
    evalBoxValues: (list_to_eval=null) ->
      if list_to_eval is null
        # 全部を評価
        list_to_eval = Object.keys(@boxes).filter((box_key) => @boxes[box_key]?)
        # Boxの値での制約を適用
        BoxConstraint.evaluate(this)

      for box_key in list_to_eval
        continue unless @boxes[box_key]?

        # Blockの数に注目
        peer_map = PeerMap.Create(BoxPeer.getPeer(box_key), @lines)
        not_block_count = 4 - peer_map.block.length
        if not_block_count < @boxes[box_key]
          # Blockの数が多すぎる
          throw new Violation(Violation.Box, "too many blocks on #{box_key}")

        else if not_block_count is @boxes[box_key]
          # Boxに必要な分のブロックがあるので、ToBeFixedはDrawにする
          for line_key in peer_map.to_be_fixed
            @drawLine(line_key) unless @lines[line_key]?

        # Drawの数に注目
        # 上のBlockの評価で、状態が変わっていることがあるので、peer_mapを更新する
        peer_map = PeerMap.Create(BoxPeer.getPeer(box_key), @lines)
        draw_count = peer_map.draw.length
        to_be_fixed_count = peer_map.to_be_fixed.length
        if draw_count > @boxes[box_key]
          throw new Violation(Violation.Box, "too many draws on #{box_key}")

        else if draw_count is @boxes[box_key]
          # Boxに必要な分のDrawがあるので、ToBeFixedはBlockにする

          for line_key in peer_map.to_be_fixed
            @blockLine(line_key) unless @lines[line_key]?

        else if draw_count + to_be_fixed_count is @boxes[box_key]
          # DrawとToBeFixedを合わせるとBoxの値になるので、
          # ToBeFixedをDrawにする

          for line_key in peer_map.to_be_fixed
            @drawLine(line_key) unless @lines[line_key]?

      return this

    isSatisfiedBoxValues: ->
      # すべてのBoxの値を満たしているか？
      for box_key, box_value of @boxes
        continue unless box_value?
        if @countDraw(BoxPeer.getPeer(box_key)) isnt box_value
          return false
      return true

    isAllLineInLoop: (start_key=null) ->
      if start_key is null
        start_key = Object.keys(@lines).filter((key) => @lines[key] is Line.Draw)[0]

      [prev_key, curr_key] = [start_key, start_key]
      count = 0
      loop
        count++
        peer_list = ConnectorPeer.getPeers(curr_key)
        peer = null
        if peer_list[0].includes(prev_key)
          peer = peer_list[1]
        else
          peer = peer_list[0]

        peer_map = PeerMap.Create(peer, @lines)
        if peer_map.draw.length is 1
          if peer_map.draw[0] is start_key
            # スタートしたLineに戻ってきた
            break

          [prev_key, curr_key] = [curr_key, peer_map.draw[0]]
        else
          # 途切れた
          return false

      return count is @totalLine

    #
    # 次の候補のLineを探す
    #
    # @param {LineKey} start_key
    # @return {false|LineKey[]} 次に試すLineのリスト、ループになっているときはfalse
    #
    nextLines: (start_key) ->
      # まずは、start_keyの両端を調べる
      for peer in ConnectorPeer.getPeers(start_key)
        peer_map = PeerMap.Create(peer, @lines)
        # つながってないので
        return peer if peer_map.draw.length is 0

      # 両端ともつながってるので、端っこを探す
      [prev_key, curr_key] = [start_key, start_key]
      loop
        for peer in ConnectorPeer.getPeers(curr_key)
          continue if peer.includes(prev_key)

          peer_map = PeerMap.Create(peer, @lines)
          # つながっているので、次のLineへ移動
          if peer_map.draw.length is 1
            # スタートしたLineに戻ってきた
            return null if peer_map.draw[0] is start_key

            [prev_key, curr_key] = [curr_key, peer_map.draw[0]]
            break

          # 途切れたので、ToBeFixedのリストを返す
          return peer_map.to_be_fixed

    #
    # 解くための最初のLineを探す
    findStartList: ->
      if @totalLine is 0
        for box_value in [3, 2, 1]
          box_list = Object.keys(@boxes).filter((key) => @boxes[key] is box_value)
          return BoxPeer.getPeer(box_list[0]) if box_list.length isnt 0
      else
        line_list = Object.keys(@lines).filter((key) => @lines[key] is Line.Draw)
        # 最初に見つかったLineの途切れたところを返す
        return @nextLines(line_list[0])

      return null

    countDraw: (key_list) -> return @countLines(key_list, Line.Draw)
    countBlock: (key_list) -> return @countLines(key_list, Line.Block)
    countUndefined: (key_list) -> return @countLines(key_list, Line.ToBeFixed)
    countLines: (key_list, status) ->
      key_list.filter((key) => @lines[key] is status).length
