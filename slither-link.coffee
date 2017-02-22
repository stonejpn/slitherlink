# ---------------------------------------------------------------------------- #
# スリザーリンクを解くスクリプト
#
# 以下のSPECの中身を書き換えて下さい。
# フォーマットは、ヨコxタテ:グリッド
# グリッドは、各々のマスに指定されている数字か、指定がない場合は"."を置きます
#
# ----
#   +   +   +   +
#         0   1
#   +   +   +   +
#                    <- この問題の場合、SPECは"3x3:.01...2.."と書きます
#   +   +   +   +
#     2
#   +   +   +   +
# ----

SPEC = '''
10x10:02..20............20.02..2.........0.03.02.0............2.10.20.0.........3..01.02............01..01
'''

# ---------------------------------------------------------------------------- #
# Constants
#
HORIZ = 'h'
VERT = 'v'
BOX = 'b'
SEP = ','

DRAW = 'd'
BLOCK = 'x'
UNDEFINED = null

# 途中経過を表示
WATCH_IN_PROGRESS = off

# run test only
TEST_MODE = off

unique_filter = (value, index, list) -> list.indexOf(value) is index

# ---------------------------------------------------------------------------- #
# Key
#
Key =
  line: (type, row, col) ->
    "#{type}#{SEP}#{row}#{SEP}#{col}"

  box: (row, col) ->
    "#{BOX}#{SEP}#{row}#{SEP}#{col}"

  toRowCol: (key) ->
    [type, row, col] = key.split(',')
    [parseInt(row, 10), parseInt(col, 10)]

  allBoxes: (width, height) ->
    key_list = []
    for row in [1..height]
      for col in [1..width]
        key_list.push(@box(row, col))
    return key_list

  eachBoxes: (width, height, callback) ->
    for box_key in @allBoxes(width, height)
      callback(box_key)

  # Boxを基準に周りのLineのリストを作成
  makeLinesOnBox: (width, height) ->
    map = {}
    for row in [1..height]
      for col in [1..width]
        box_key = @box(row, col)

        map[box_key] = []
        # top
        map[box_key].push(@line(HORIZ, row - 1, col))
        # left
        map[box_key].push(@line(VERT, row, col))
        # bottom
        map[box_key].push(@line(HORIZ, row, col))
        # right
        map[box_key].push(@line(VERT, row, col - 1))
    return map

  eachHorizLine: (width, height, callback) ->
    for row in [0..height]
      for col in [1..width]
        line_key = @line(HORIZ, row, col)
        callback(line_key, row, col)

  eachVertLine: (width, height, callback) ->
    for row in [1..height]
      for col in [0..width]
        line_key = @line(VERT, row, col)
        callback(line_key, row, col)

  makeBoxesOnLine: (width, height) ->
    peer = {}

    # ヨコの処理
    @eachHorizLine(width, height, (line_key, row, col) =>
      peer[line_key] = []
      # 上のBox
      peer[line_key].push(@box(row, col)) if row > 0
      # 下のBox
      peer[line_key].push(@box(row + 1, col)) if row < height
      )

    # タテを処理
    @eachVertLine(width, height, (line_key, row, col) =>
      peer[line_key] = []
      # 左のBox
      peer[line_key].push(@box(row, col)) if col > 0
      # 右のBox
      peer[line_key].push(@box(row, col + 1)) if col < width
      )

    return peer

  connectorPeer: (width, height) ->
    peer = {}

    # Connectorから見て、上->右->下->左と時計回りで追加する

    @eachHorizLine(width, height, (line_key, row, col) =>
      # 右側のConnector
      right_list = []
      right_list.push(@line(VERT, row, col)) if row > 0
      right_list.push(@line(HORIZ, row, col + 1)) if col < width
      right_list.push(@line(VERT, row + 1, col)) if row < height

      # 左側のConnector
      left_list = []
      left_list.push(@line(VERT, row, col - 1)) if row > 0
      left_list.push(@line(VERT, row + 1, col - 1)) if row < height
      left_list.push(@line(HORIZ, row, col - 1)) if col > 1

      peer[line_key] = [right_list, left_list]
      )

    @eachVertLine(width, height, (line_key, row, col) =>
      # 上のConnector
      top_list = []
      top_list.push(@line(VERT, row - 1, col)) if row > 1
      top_list.push(@line(HORIZ, row - 1, col + 1)) if col < width
      top_list.push(@line(HORIZ, row - 1, col)) if col > 0

      # 下のConnector
      bottom_list = []
      bottom_list.push(@line(HORIZ, row, col + 1)) if col < width
      bottom_list.push(@line(VERT, row + 1, col)) if row < height
      bottom_list.push(@line(HORIZ, row, col)) if col > 0

      peer[line_key] = [top_list, bottom_list]
      )

    return peer

# ---------------------------------------------------------------------------- #
# Matrix
#
class Matrix
  # Boxの周りのLine
  #  Object: box_key, line_key[]
  @LinesOnBox: null

  # Lineに接するBox
  #  Object: line_key, box_key[]
  @BoxesOnLine: null

  # Connectorを共有するLine
  #  Object: line_key, line_key[]
  @ConnectorPeer: null

  @round: 1

  @forceQuit: false

  lines: null
  boxes: null
  lineCount: null
  depth: null

  @InitMaps: (width, height) ->
    Matrix.LinesOnBox = Key.makeLinesOnBox(width, height)
    Matrix.BoxesOnLine = Key.makeBoxesOnLine(width, height)
    Matrix.ConnectorPeer = Key.connectorPeer(width, height)

  constructor: (@width, @height) ->
    @lines = {}
    Key.eachHorizLine(@width, @height, (key) => @lines[key] = UNDEFINED)
    Key.eachVertLine(@width, @height, (key) => @lines[key] = UNDEFINED)

    @boxes = {}
    Key.eachBoxes(@width, @height, (key) => @boxes[key] = null)

    @lineCount = 0
    @depth = 1

  parseGrid: (grid) ->
    row = 1
    for i in [0..(grid.length - 1)] by @width
      line = grid.substr(i, @width)
      col = 1
      for c in line
        if c.match(/[0123]/)
          box_key = Key.box(row, col)
          @boxes[box_key] = parseInt(c, 10)
        col++
      row++

    @initBlocks()

    return this

  initBlocks: ->
    # 0の処理だけは先にやってしまう
    block_list = []
    for box_key in Object.keys(@boxes)
      if @boxes[box_key] is 0
        for line_key in Matrix.LinesOnBox[box_key]
          @lines[line_key] = BLOCK
          block_list.push(line_key)

    # 問題に整合性が取れているかチェック
    @inspectBoxes(Object.keys(@boxes))

    # BLOCKの後処理
    @didBlock(block_list.filter(unique_filter))

  drawLine: (line_key) ->
    if Matrix.forceQuit
      throw {message: "Force Quit", matrix: this}

    # --------------------------------
    # 途中経過を表示
    preserved_round = Matrix.round
    watching = false
    if (not TEST_MODE) and WATCH_IN_PROGRESS
      unit = 10
      console.log("")
      console.log("-------- Round ##{Matrix.round} depth:#{@depth} --------")
      console.log("attempt to draw line at #{line_key}")
    # --------------------------------

    if @lines[line_key]?
      throw (message: "LineViolation: attempt to draw where line was fixed at #{line_key}")

    # LineのステータスをDRAWに
    @lines[line_key] = DRAW
    @lineCount++

    # DRAWにすることで、他のLineがBLOCKになるケースを検出
    effected_lines = @didDraw(line_key)
    if effected_lines.length isnt 0
      additiona_block = @didBlock(effected_lines)
      effected_lines = effected_lines.concat(additiona_block)
    effected_lines = effected_lines.filter(unique_filter)

    # --------------------------------
    # 途中経過を表示
    if watching
      unit = 10
      if Matrix.round % unit is 0
        Solver.show(this)
        console.log("")
    # --------------------------------

    @inspectBoxes(@findBoxes(effected_lines))
    connected = @inspectConnectors(line_key)
    if connected
      @sufficientAllBoxes()
      @inspectLoop(line_key)
      return this

    # 次のLineをDraw
    Matrix.round++
    console.log("drawing at #{line_key} with no violation, next round.") if watching

    line_list = Matrix.ConnectorPeer[line_key][0]
    if @countLines(line_list, DRAW) isnt 0
      line_list = Matrix.ConnectorPeer[line_key][1]
    line_list = line_list.filter((key) => @lines[key] is UNDEFINED)
    if line_list.length is 1
      return @drawLine(line_list[0])
    else
      for next_line in line_list
        try
          m = @clone()
          return m.drawLine(next_line)
        catch error
          throw error if error instanceof Error
          console.log(error.message) if watching

    throw {message: "Unable to solve, play back to Round ##{preserved_round - 1}", conclusion: true}

  ###
    LineをDRAWにしたことで発生するBLOCK

    * 接するBox
    * 両端のConnector

    @param {string} line_key
  ###
  didDraw: (line_key) ->
    mod_lines = []
    self = this
    block_callback = (key) ->
      unless self.lines[key]?
        self.lines[key] = BLOCK
        mod_lines.push(key)

    # 隣接するBoxの値とDRAWの数が一致した場合、他のLineはBLOCKにする
    for box_key in Matrix.BoxesOnLine[line_key]
      draw_count = @countLines(Matrix.LinesOnBox[box_key], DRAW)
      if draw_count is @boxes[box_key]
        Matrix.LinesOnBox[box_key].forEach(block_callback)

    # Connectorで、DRAWの数が2になったら、他のLineはBLOCKにする
    for key_list in Matrix.ConnectorPeer[line_key]
      draw_count = @countLines(key_list.concat(line_key), DRAW)
      if draw_count is 2
        key_list.forEach(block_callback)

    return mod_lines

  ###
    BLOCKしたLineのConnectorPeerを調べて、行き止まりになってるLineをBLOCKにする
  ###
  didBlock: (block_list) ->
    effected_list = []
    loop
      mod_list = []
      # BLOCKされたLine(line_key)の、
      for line_key in block_list
        # ConnectorPeerを調べて、
        for line_list in Matrix.ConnectorPeer[line_key]
          # Peerに含まれるLine(conn_key)の、
          for conn_key in line_list
            continue if @lines[conn_key] isnt UNDEFINED
            if @isDeadEnd(conn_key)
              # Line(conn_key)をBLOCKに
              @lines[conn_key] = BLOCK
              mod_list.push(conn_key)
              continue

      break if mod_list.length is 0
      block_list = mod_list
      effected_list = effected_list.concat(mod_list)

    return effected_list.filter(unique_filter)

  isDeadEnd: (line_key) ->
    for peer_list in Matrix.ConnectorPeer[line_key]
      block_count = @countLines(peer_list, BLOCK)
      return true if block_count is peer_list.length
    return false

  ###
    Boxについて検査する
    * DRAWの数が、Boxの値より多い
    * BLOCKが多すぎて、Boxの値を満たせない
    ときに、BoxViolationをthrowする

    @param {string[]} box_key_list Boxキーのリスト
  ###
  inspectBoxes: (box_key_list) ->
    for box_key in box_key_list
      continue if (not @boxes[box_key]?) or @boxes[box_key] is 0

      draw_count = @countLines(Matrix.LinesOnBox[box_key], DRAW)
      if draw_count > @boxes[box_key]
        throw {message: "BoxViolation: too many lines at #{box_key}"}

      block_count = @countLines(Matrix.LinesOnBox[box_key], BLOCK)
      if (4 - block_count) < @boxes[box_key]
        throw {message: "BoxViolation: too few available at #{box_key}"}

  ###
    LineのリストからそのLineに接するBoxのリストを見つける

    @param {string[]} line_keys Lineのリスト
    @return {string[]} Boxのリスト
  ###
  findBoxes: (line_keys) ->
    box_list = []
    for line_key in line_keys
      box_list = box_list.concat(Matrix.BoxesOnLine[line_key])
    # 重複を削除
    return box_list.filter((box_key, idx, list) ->
      list.indexOf(box_key) is idx
      )

  ###
    両端のConnectorについて調査

    @param {string} line_key
    @return {boolean} 両端がDRAWでつながっているときtrue
  ###
  inspectConnectors: (line_key) ->
    connected = 0
    for line_list in Matrix.ConnectorPeer[line_key]
      draw_count = @countLines(line_list.concat(line_key), DRAW)
      switch draw_count
        when 1
          # 他にDRAWできる余地があるか？
          available_count = @countLines(line_list, UNDEFINED)
          if available_count is 0
            throw {message: "ConnectorViolation: dead end at #{line_key}"}
        when 2
          # つながっている
          connected++
        else
          # 3か4 (line_keyがDRAWされているので、0の可能性はない)
          throw {message: "ConnectorViolation: too many draw at #{line_key}"}

    return connected is 2

  ###
    Boxの値をすべて満たしているか検査
  ###
  sufficientAllBoxes: ->
    for box_key, box_value of @boxes
      continue unless box_value?

      draw_count = @countLines(Matrix.LinesOnBox[box_key], DRAW)
      if draw_count isnt box_value
        throw {message: "BoxViolation: not sufficient at #{box_key}"}

  ###
    ループの検査

    line_keyからDRAWを辿って、
    ・line_keyに帰ってこれるか？
    ・辿ったLineの数が、全体のDRAWの数と一致するか？
  ###
  inspectLoop: (line_key) ->
    # DRAWを辿って、line_keyに帰ってこれるか？
    [start_line, focus_line, prev_line] = [line_key, line_key, line_key]
    line_count = 1
    loop
      # 直前のLineが含まれていないConnectorを選ぶ
      line_list = Matrix.ConnectorPeer[focus_line][0]
      if line_list.includes(prev_line)
        line_list = Matrix.ConnectorPeer[focus_line][1]

      draw_list = line_list.filter((key) => @lines[key] is DRAW)
      if draw_list.length isnt 1
        throw {message: "LoopViolation: could not return to start line"}

      # スタートしたLineに戻ってきた
      break if draw_list[0] is start_line

      [prev_line, focus_line] = [focus_line, draw_list[0]]
      line_count++

    draw_count = @countLines(Object.keys(@lines), DRAW)
    if line_count isnt draw_count
      throw {message: "LoopViolation: find line outside of loop"}

  ###
    statusと一致するLineを数える
  ###
  countLines: (line_keys, status) ->
    count = 0
    count++ for key in line_keys when @lines[key] is status
    return count

  ###
    最初に試すBoxをピックアップ
  ###
  findStartBox: ->
    # box_valueは、1, 3, 2の順番が分岐が少ない
    for box_value in [1, 3, 2]
      box_list = Object.keys(@boxes).filter((key) => @boxes[key] is box_value)
      if box_list.length > 0
        return box_list[0]

  clone: ->
    new_m = new Matrix(@width, @height)

    for key, value of @lines
      new_m.lines[key] = value
    for key, value of @boxes
      new_m.boxes[key] = value

    new_m.linecount = @lineCount
    new_m.depth = @depth + 1

    return new_m

# ---------------------------------------------------------------------------- #
# Solver
#
Solver =
  run: (spec) ->
    matrix = @parseGrid(spec)

    # 初期状態を表示
    console.log("---- Puzzle ----")
    @show(matrix, false)
    console.log("")

    @solve(matrix)

  parseGrid: (spec) ->
    [width, height, grid] = spec.split(/[x:]/)
    width = parseInt(width, 10)
    height = parseInt(height, 10)

    # BoxやPeerを初期化
    Matrix.InitMaps(width, height)

    matrix = new Matrix(width, height)
    return matrix.parseGrid(grid)

  solve: (matrix) ->
    box_key = matrix.findStartBox()
    for line_key in Matrix.LinesOnBox[box_key]
      try
        m = matrix.clone()
        m = m.drawLine(line_key)

        # 解いている最中に矛盾が発生すると、例外が飛ぶので、ここまで来ると解けている状態

        # 解答を表示
        console.log("---- Solved ----")
        console.log("Round: #{Matrix.round} depth: #{m.depth}")
        @show(m, false)
        break
      catch error
        throw error if error instanceof Error
        if WATCH_IN_PROGRESS
          if error.conclusion?
            console.log(error.message)

  show: (matrix, with_x=true) ->
    for row in [0..matrix.height]
      # タテのLineとBoxの値を書く
      if row > 0
        buffer = ''
        for col in [0..matrix.width]
          if col > 0
            # Boxの値を書く
            box_key = Key.box(row, col)
            if matrix.boxes[box_key]?
              buffer += " #{matrix.boxes[box_key]} "
            else
              buffer += '   '

          line_key = Key.line(VERT, row, col)
          switch matrix.lines[line_key]
            when DRAW
              buffer += '|'
            when BLOCK
              buffer += if with_x then 'x' else ' '
            else
              buffer += ' '
        console.log(buffer)

      # ヨコのLineを書く
      buffer = '+'
      for col in [1..matrix.width]
        line_key = Key.line(HORIZ, row, col)
        switch matrix.lines[line_key]
          when DRAW
            buffer += '---'
          when BLOCK
            buffer += if with_x then ' x ' else '   '
          else
            buffer += '   '
        buffer += '+'
      console.log(buffer)

# ---------------------------------------------------------------------------- #
# Test
#
if TEST_MODE
  console.log("-------- TEST MODE --------")
  passed = 0

  equals = (title, a, e) ->
    unless JSON.stringify(a) is JSON.stringify(e)
      throw {message: "#{title}:\nexpect:#{JSON.stringify(e)}\nactual:#{JSON.stringify(a)}"}
    passed++

  expect_throw = (title, expect_message, callback) ->
    matcher = new RegExp("^#{expect_message}")
    try
      callback()
      throw {message: "#{title}: excpetion was not thrown"}
    catch error
      if matcher.test(error.message)
        passed++
      else
        throw {message: "#{title}: Unexpected exception.\n  #{error.message}"}

  expect_not_throw = (title, callback) ->
    try
      callback()
      passed++
    catch error
      throw {message: "#{title}: Unexpected exception.\n  #{error.message}"}

  try
    # -----------------------------
    #  Box Mapのテスト

    # Box Map
    box_map = Key.makeLinesOnBox(3, 3)
    box_key = Key.box(2, 1)
    expect = ['h,1,1', 'v,2,1', 'h,2,1', 'v,2,0']
    equals("LinesOnBox", box_map[box_key], expect)

    # -----------------------------
    # Peerのテスト
    #

    # Box Peer
    box_peer = Key.makeBoxesOnLine(3, 3)
    line_key = Key.line(VERT, 1, 0)
    expect = ["b,1,1"]
    equals('BoxesOnLine1', box_peer[line_key], expect)

    line_key = Key.line(HORIZ, 2, 3)
    expect = ["b,2,3", "b,3,3"]
    equals('BoxesOnLine2', box_peer[line_key], expect)

    # Connector Peer
    conn_peer = Key.connectorPeer(3, 3)

    line_key = Key.line(HORIZ, 0, 1)
    expect = [['h,0,2', 'v,1,1'], ['v,1,0']]
    equals('ConnectorPeer1', conn_peer[line_key], expect)

    line_key = Key.line(VERT, 3, 1)
    expect = [['v,2,1', 'h,2,2', 'h,2,1'], ['h,3,2', 'h,3,1']]
    equals('ConnectorPeer2', conn_peer[line_key], expect)

    line_key = Key.line(VERT, 2, 2)
    expect = [['v,1,2', 'h,1,3', 'h,1,2'], ['h,2,3', 'v,3,2', 'h,2,2']]
    equals('ConnectorPeer3', conn_peer[line_key], expect)

    # -----------------------------
    # parseGridのテスト
    #
    Matrix.InitMaps(3, 3)
    matrix = new Matrix(3, 3)
    expect = ['b,1,1', 'b,1,2', 'b,1,3', 'b,2,1', 'b,2,2', 'b,2,3', 'b,3,1', 'b,3,2', 'b,3,3']
    equals('Matrix1', Object.keys(matrix.boxes), expect)

    matrix.parseGrid('.01...2..')
    preserve_matrix = matrix.clone()
    expect_list = [
      Key.line(HORIZ, 0, 2)
      Key.line(VERT, 1, 2)
      Key.line(HORIZ, 1, 2)
      Key.line(VERT, 1, 1)
      Key.line(HORIZ, 0, 1)
      Key.line(VERT, 1, 0)
      Key.line(HORIZ, 0, 3)
      Key.line(VERT, 1, 3)
    ]
    block_count = 0
    for line_key in Object.keys(matrix.lines)
      if matrix.lines[line_key] is BLOCK
        block_count++
        unless expect_list.includes(line_key)
          throw {message: "parseGrid1: Unexpected line_key that blocked at #{line_key}"}
    if block_count isnt expect_list.length
      throw {message: "parseGrid1: Unmatched number of blocked"}
    passed++

    # 問題の整合性が取れていない
    expect_throw('parseGrid2', 'BoxViolation: too few available at b,2,2', ->
      matrix = new Matrix(3, 3)
      matrix.parseGrid('.0.03....')
      )

    # -----------------------------
    # countLinesのテスト
    #
    matrix = preserve_matrix.clone()
    line_key = Key.line(HORIZ, 1, 3)
    matrix.lines[line_key] = DRAW
    box_key = Key.box(1, 3)
    draw_count = matrix.countLines(Matrix.LinesOnBox[box_key], DRAW)
    if draw_count is 1
      passed++
    else
      throw {message: "countLines: Unmatch number of line drawn."}
    block_count = matrix.countLines(Matrix.LinesOnBox[box_key], BLOCK)
    if block_count is 3
      passed++
    else
      throw {message: "countLines: Unmatch number of blocked."}

    # -----------------------------
    # drawLineのテスト
    #
    # すでにBLOCKされているLineにDrawしようとする
    expect_throw('drawLine1', 'LineViolation', ->
      matrix = preserve_matrix.clone()
      line_key = Key.line(HORIZ, 0, 2)
      matrix.drawLine(line_key)
      )

    # すでにDRAWされているところに、再度Drawしようとする
    expect_throw('drawLine2', 'LineViolation', ->
      matrix = preserve_matrix.clone()
      line_key = Key.line(HORIZ, 1, 3)
      matrix.lines[line_key] = DRAW
      matrix.drawLine(line_key)
      )

    # -----------------------------
    # didDrawのテスト
    #
    matrix = preserve_matrix.clone()
    matrix.lines[Key.line(VERT, 2, 2)] = DRAW
    key = Key.line(HORIZ, 2, 3)
    matrix.lines[key] = DRAW
    mod_lines = matrix.didDraw(key)
    if mod_lines.length isnt 2
      throw {message: "didDraw1: Unmatch number of line modified."}
    if mod_lines.includes(Key.line(HORIZ, 2, 2)) and mod_lines.includes(Key.line(VERT, 3, 2))
      passed++
    else
      throw {message: "didDraw1: Unexpected line was modified. #{mod_lines.join(' ')}"}

    # -----------------------------
    # inspectConnectorsのテスト
    #
    expect_throw('inspectConnectors1', 'ConnectorViolation: dead end at h,1,1', ->
      # 行き止まり
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(VERT, 2, 0)] = BLOCK
      matrix.drawLine(Key.line(HORIZ, 1, 1))
      )
    expect_throw('inspectConnectors2', 'ConnectorViolation: too many draw at h,2,2', ->
      # 枝分かれ
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(VERT, 2, 2)] = DRAW
      matrix.lines[Key.line(VERT, 3, 2)] = DRAW
      matrix.drawLine(Key.line(HORIZ, 2, 2))
      )

    # -----------------------------
    # sufficientAllBoxesのテスト
    #
    expect_throw('sufficientAllBoxes1', 'BoxViolation: not sufficient at b,3,1', ->
      # 足りてない
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(HORIZ, 1, 3)] = DRAW
      matrix.sufficientAllBoxes()
      )
    expect_not_throw('sufficientAllBoxes2', ->
      # 足りてる
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(HORIZ, 1, 3)] = DRAW
      matrix.lines[Key.line(VERT, 3, 0)] = DRAW
      matrix.lines[Key.line(HORIZ, 3, 1)] = DRAW
      matrix.sufficientAllBoxes()
      )

    # -----------------------------
    # inspectLoopのテスト
    #
    expect_throw('inspectLoop1', 'LoopViolation: could not return to start line', ->
      matrix = preserve_matrix.clone()
      # 戻ってこれない
      matrix.lines[Key.line(VERT, 2, 2)] = DRAW
      matrix.lines[Key.line(HORIZ, 1, 3)] = DRAW
      matrix.lines[Key.line(VERT, 2, 3)] = DRAW
      matrix.lines[Key.line(VERT, 3, 3)] = DRAW
      matrix.lines[Key.line(HORIZ, 3, 3)] = DRAW
      matrix.lines[Key.line(HORIZ, 3, 2)] = DRAW
      matrix.lines[Key.line(VERT, 3, 1)] = DRAW
      matrix.inspectLoop(Key.line(HORIZ, 1, 3))
      )
    expect_not_throw('inspectLoop2', ->
      # 戻ってこれる
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(HORIZ, 1, 3)] = DRAW
      matrix.lines[Key.line(VERT, 2, 3)] = DRAW
      matrix.lines[Key.line(VERT, 3, 3)] = DRAW
      matrix.lines[Key.line(HORIZ, 3, 3)] = DRAW
      matrix.lines[Key.line(VERT, 3, 2)] = DRAW
      matrix.lines[Key.line(VERT, 2, 2)] = DRAW
      matrix.inspectLoop(Key.line(HORIZ, 1, 3))
      )
    expect_throw('inspectLoop3', 'LoopViolation: find line outside of loop', ->
      matrix = preserve_matrix.clone()
      matrix.lines[Key.line(HORIZ, 1, 3)] = DRAW
      matrix.lines[Key.line(VERT, 2, 3)] = DRAW
      matrix.lines[Key.line(HORIZ, 2, 3)] = DRAW
      matrix.lines[Key.line(VERT, 2, 2)] = DRAW
      matrix.lines[Key.line(VERT, 3, 1)] = DRAW # これがループ外
      matrix.inspectLoop(Key.line(HORIZ, 1, 3))
      )

    # All tests passed
    console.log("OK!!\n#{passed} tests passed.")
  catch error
    throw error if error instanceof Error
    console.log("Failed...\n#{error.message}")

  return

# ---------------------------------------------------------------------------- #
# Main Sequence
#
Solver.run(SPEC.replace(/\s/g, ''))
