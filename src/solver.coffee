EventEmitter = require "events"

Box = require "./box"
BoxPeer = require "./box-peer"
ConnectorPeer = require "./connector-peer"
Matrix = require "./matrix"
Logger = require "./logger"
Worker = require "./worker"

###
# Solver
###
module.exports =
  event: null
  run: (puzzule, show_in_progress=false) ->
    [size, grid] = puzzule.replace(/\s+/g, '').split(':')
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
      @event.emit('next', matrix)
    catch error
      if error.stack?
        console.error("#{error.stack}")
      else
        console.error("#{error}")

  solved: (matrix) ->
    @event.removeAllListeners()
    Logger.solved(matrix)

  notSolved: (message) ->
    @event.removeAllListeners()
    console.log("Not solved.")
    console.log(message)
