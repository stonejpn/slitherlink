EventEmitter = require "events"

Box = require "./box"
BoxPeer = require "./box-peer"
ConnectorPeer = require "./connector-peer"
Matrix = require "./matrix"
Logger = require "./logger"
Worker = require "./worker"
Violation = require "./violation"

###
# Solver
###
module.exports =
  event: null

  run: (puzzle, show_in_progress=false) ->
    [size, grid] = puzzle.replace(/\s+/g, '').split(':')
    [width, height] = size.split('x').map((c) -> parseInt(c, 10))

    # 初期化
    Logger.showInProgress = show_in_progress
    ConnectorPeer.initialize(width, height)
    BoxPeer.initialize(Box.all(width, height))

    @event = new EventEmitter()
    @event.on('solved', (matrix) => @solved(matrix))
    @event.on('not-solved', (message) => @notSolved(message))

    try
      # /* @param {Matrix} matrix */
      matrix = new Matrix(width, height)
      matrix.parseGrid(grid)
      Logger.initialized(matrix)

      matrix.evalBoxValues()
      Logger.headerInProgress("Initialized")
      Logger.matrixInProgress(matrix)

      worker = new Worker(@event)

      line_list = matrix.findStartList()
      if line_list?
        @event.emit('draw', JSON.stringify(matrix), line_key) for line_key in line_list
      else
        unless worker.checkSolved(matrix)
          @notSolved("Something goes wrong.")
          Logger.showMatrix(matrix, true)
    catch error
      if error instanceof Violation
        @notSolved("Failed Initialization.\n#{error}")
      else if error.stack?
        console.error("#{error.stack}")

  solved: (matrix) ->
    @event.removeAllListeners()
    Logger.solved(matrix)
    Logger.info("Attempt: #{Worker.workload}")

  notSolved: (message) ->
    @event.removeAllListeners()
    console.log("Not solved.")
    console.log(message)
