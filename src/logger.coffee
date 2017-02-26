Line = require "./line"
Box = require "./box"

###
  Logger
###
module.exports =
  showInProgress: false

  initialized: (matrix) ->
    @header("Puzzle")
    @showMatrix(matrix)

  solved: (matrix) ->
    @header("Solved")
    @showMatrix(matrix)

  headerInProgress: (message) ->
    return unless @showInProgress
    @header(message)

  matrixInProgress: (matrix, title="") ->
    return unless @showInProgress

    console.log(title) if title isnt ""
    @showMatrix(matrix, true) if matrix?

  messageInProgress: (message) ->
    return unless @showInProgress
    console.log(message)

  info: (message) ->
    console.log(message)

  header: (message) ->
    console.log("-------- #{message} --------")

  showMatrix: (matrix, with_x=false) ->
    for row in [0..matrix.height]
      # タテのLineとBoxの値を書く
      if row > 0
        buffer = ''
        for col in [0..matrix.width]
          if col > 0
            # Boxの値を書く
            box_key = Box.key(row, col)
            if matrix.boxes[box_key]?
              buffer += " #{matrix.boxes[box_key]} "
            else
              buffer += '   '

          line_key = Line.vert(row, col)
          switch matrix.lines[line_key]
            when Line.Draw
              buffer += '|'
            when Line.Block
              buffer += if with_x then 'x' else ' '
            else
              buffer += ' '
        console.log(buffer)

      # ヨコのLineを書く
      buffer = '+'
      for col in [1..matrix.width]
        line_key = Line.horiz(row, col)
        switch matrix.lines[line_key]
          when Line.Draw
            buffer += '---'
          when Line.Block
            buffer += if with_x then ' x ' else '   '
          else
            buffer += '   '
        buffer += '+'
      console.log(buffer)
    console.log("")
