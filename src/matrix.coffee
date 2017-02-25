'use strict'

Line = require "./line"
Box = require "./box"
BoxPeer = require "./box-peer"
ConnectorPeer = require "./connector-peer"
Violation = require "./violation"

module.exports =
  class Matrix
    lines: null
    boxes: null
    totalLine: 0

    # Arrayの重複を取り除くフィルター(よく使うので定義しておく)
    unique_filter = (value, idx, list) -> list.indexOf(value) is idx

    # objectの中で、valueの値を持つキーを見つける
    # @return {Array}
    keys_with_value = (obj, value) ->
      callback = (key) -> obj[key] is value
      Object.keys(obj).filter(callback, {obj, value})

    filter_obj = (obj, key_list) ->
      new_obj = {}
      for key in key_list
        new_obj[key] = obj[key]
      return new_obj

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

  #
    # @param {integer} width
    # @param {integer} height
    #
    constructor: (@width, @height) ->
      @lines = {}
      Line.all(@width, @height, (key) => @lines[key] = Line.UNDEFINED)
      @boxes = {}
      Box.all(@width, @height, (key) => @boxes[key] = Box.UNDEFINED)

      @totalLine = 0

    #
    # クローン
    # @retrun {Matrix}
    #
    clone: ->
      new_matrix = new Matrix(@width, @height)
      new_matrix.lines = Object.assign({}, @lines)
      new_matrix.boxes = Object.assign({}, @boxes)
      return new_matrix
    
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

      # 値が0のBoxを検出
      box_list = keys_with_value(@boxes, 0)
      for box_key in box_list
        line_list = BoxPeer.getPeer(box_key)
        for line_key in line_list
          @blockLine(line_key) unless @lines[line_key]?

      return this

    #
    # LineをDrawに変更する
    #
    drawLine: (line_key) ->
      if @lines[line_key]?
        throw new Violation(Violation.Line, "draw line(#{line_key}) has been fixed.")

      @lines[line_key] = Line.DRAW
      @totalLine++

      @lineChanged(line_key)
      if @isConnected(line_key)
        @inspectLoop(line_key)

    #
    # LineをBlockに変更する
    #
    blockLine: (line_key) ->
      if @lines[line_key]?
        throw new Violation(Violation.Line, "block line(#{line_key}) has been fixed.")

      @lines[line_key] = Line.BLOCK
      @lineChanged(line_key)

    #
    # Lineの値を変えた後の処理
    #
    lineChanged: (changed_line) ->
      # BoxPeerを調べる
      for box_key in BoxPeer.getBoxes(changed_line)
        continue unless @boxes[box_key]?

        line_list = BoxPeer.getPeer(box_key)
        line_map = filter_obj(@lines, line_list)

        block_count = Line.countBlock(line_map)
        if block_count > (4 - @boxes[box_key])
          throw new Violation(Violation.Box, "too many blocks on #{box_key}")

        draw_count = Line.countDraw(line_map)
        if draw_count > @boxes[box_key]
          throw new Violation(Violation.Box, "too many draws on #{box_key}")

        if draw_count is @boxes[box_key]
          for line_key in line_list
            if not @lines[line_key]?
              @blockLine(line_key)

      # ConnectorPeerを調べる
      for line_list in ConnectorPeer.getPeers(changed_line)
        line_list = line_list.concat(changed_line)
        line_map = filter_obj(@lines, line_list)
        if Line.countBlock(line_map) >= (line_list.length - 1)
          # 行き止まり
          for line_key in line_list
            if not @lines[line_key]?
              @blockLine(line_key)

        draw_count = Line.countDraw(line_map)
        if draw_count is 1
          if Line.countUndefined(line_map) is 0
            throw new Violation(Violation.Connector, "dead end #{changed_line}")
        else if draw_count is 2
          # Drawが2本あったら、他はBlockにする
          for line_key in line_list
            if not @lines[line_key]?
              @blockLine(line_key)
        else if draw_count > 2
          throw new Violation(Violation.Connector, "too many draws #{changed_line}")

    isConnected: (line_key) ->
      return false if @lines[line_key] isnt Line.DRAW

      connected = 0
      for line_list in ConnectorPeer.getPeers(line_key)
        line_map = filter_obj(@lines, line_list)
        connected += Line.countDraw(line_map)

      return connected is 2

    inspectLoop: (start_key) ->
      # すべてのBoxの値を満たしているか？
      for box_key, box_value of @boxes
        continue unless box_value?

        line_map = filter_obj(@lines, BoxPeer.getPeer(box_key))
        if Line.countDraw(line_map) isnt box_value
          throw new Violation(Violation.Loop, "unsatisfied box value #{box_key}")

      # ループを辿って自身に戻ってこれるか？
      [prev_key, curr_key] = [start_key, start_key]
      loop
        find = false
        for peer in ConnectorPeer.getPeers(curr_key)
          unless peer.includes(prev_key)
            for key in peer
              if @lines[key] is Line.DRAW
                [prev_key, curr_key] = [curr_key, key]
                find = true
                break
            break if find
        throw new Violation(Violation.Loop, "not loop") unless find

        break if curr_key is start_key

