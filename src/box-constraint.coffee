'use strict'

Line = require "./line"
Box = require "./box"
BoxPeer = require "./box-peer"

# 循環参照になるため、Matrixはrequireしない
# Matrix = require "./matrix"

# --------------------------------
# BoxConstraint
# --------------------------------
module.exports =
  evaluate: (matrix) ->
    width = matrix.getWidth()
    height = matrix.getHeight()

    @constraint0(matrix, width, height)
    @constraint3(matrix, width, height)
    @corners(matrix, width, height)

  constraint0: (matrix, width, height) ->
    Box.all(width, height, (box_key) ->
      if matrix.boxValue(box_key) is 0
        for line_key in BoxPeer.getPeer(box_key)
          matrix.blockLine(line_key) unless matrix.lineValue(line_key)?
    )

  constraint3: (matrix, width, height) ->
    Box.all(width, height, (box_key) ->
      return unless matrix.boxValue(box_key) is 3

      [id, row, col] = box_key.split(',')
      row = parseInt(row, 10)
      col = parseInt(col, 10)

      # 隣あった3は3本引ける
      draw_line = []
      if col < width
        # 右隣
        right_value = matrix.boxValue(Box.key(row, col + 1))
        if right_value is 3
          draw_line.push(Line.vert(row, col - 1))
          draw_line.push(Line.vert(row, col))
          draw_line.push(Line.vert(row, col + 1))
      if row < height
        # 下
        lower_value = matrix.boxValue(Box.key(row + 1, col))
        if lower_value is 3
          draw_line.push(Line.horiz(row - 1, col))
          draw_line.push(Line.horiz(row, col))
          draw_line.push(Line.horiz(row + 1, col))

      # ３同士の斜め
      if row < height
        if col > 1
          # 左斜め下
          left_value = matrix.boxValue(Box.key(row + 1, col - 1))
          if left_value is 3
            draw_line.push(Line.horiz(row - 1, col))
            draw_line.push(Line.vert(row, col))
            draw_line.push(Line.horiz(row + 1, col - 1))
            draw_line.push(Line.vert(row + 1, col - 2))
        if col < width
          # 右斜め下
          right_value = matrix.boxValue(Box.key(row + 1, col + 1))
          if right_value is 3
            draw_line.push(Line.horiz(row - 1, col))
            draw_line.push(Line.vert(row, col - 1))
            draw_line.push(Line.horiz(row + 1, col + 1))
            draw_line.push(Line.vert(row + 1, col + 1))

      # 3の斜めに0がある
      if row > 1
        if col > 1
          # 左斜め上に0がある
          if matrix.boxValue(Box.key(row - 1, col - 1)) is 0
            draw_line.push(Line.horiz(row - 1, col))
            draw_line.push(Line.vert(row, col - 1))
        if col < width
          # 右ななめ上に0がある
          if matrix.boxValue(Box.key(row - 1, col + 1)) is 0
            draw_line.push(Line.horiz(row - 1, col))
            draw_line.push(Line.vert(row, col))
      if row < height
        if col > 1
          # 左ななめ下に0がある
          if matrix.boxValue(Box.key(row + 1, col - 1)) is 0
            draw_line.push(Line.horiz(row, col))
            draw_line.push(Line.vert(row, col - 1))
        if col < width
          # 右ななめ下に0がある
          if matrix.boxValue(Box.key(row + 1, col + 1)) is 0
            draw_line.push(Line.horiz(row, col))
            draw_line.push(Line.vert(row, col))

      for line_key in draw_line
        matrix.drawLine(line_key) unless matrix.lineValue(line_key)?
    )

  corners: (matrix, width, height) ->
    # 4つの角の制約
    block_list = []
    draw_list = []
    # 左上
    box_value = matrix.boxValue(Box.key(1, 1))
    switch box_value
      when 1
        block_list.push(Line.horiz(0, 1), Line.vert(1, 0))
      when 2
        draw_list.push(Line.horiz(0, 2), Line.vert(2, 0))
      when 3
        draw_list.push(Line.horiz(0, 1), Line.vert(1, 0))

    # 右上
    box_value = matrix.boxValue(Box.key(1, width))
    switch box_value
      when 1
        block_list.push(Line.horiz(0, width), Line.vert(1, width))
      when 2
        draw_list.push(Line.horiz(0, width - 1), Line.vert(2, width))
      when 3
        draw_list.push(Line.horiz(0, width), Line.vert(1, width))

    # 左下
    box_value = matrix.boxValue(Box.key(height, 1))
    switch box_value
      when 1
        block_list.push(Line.horiz(height, 1), Line.vert(height, 0))
      when 2
        draw_list.push(Line.horiz(height, 2), Line.vert(height - 1, 0))
      when 3
        draw_list.push(Line.horiz(height, 1), Line.vert(height, 0))

    # 右下
    box_value = matrix.boxValue(Box.key(height, width))
    switch box_value
      when 1
        block_list.push(Line.horiz(height, width), Line.vert(height, width))
      when 2
        draw_list.push(Line.horiz(height, width - 1), Line.vert(height - 1, width))
      when 3
        draw_list.push(Line.horiz(height, width), Line.vert(height, width))

    for line_key in block_list
      matrix.blockLine(line_key) unless matrix.lineValue(line_key)?
    for line_key in draw_list
      matrix.drawLine(line_key) unless matrix.lineValue(line_key)?
