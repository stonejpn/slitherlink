Matrix = require "./matrix"
Violation = require "./violation"
Logger = require "./logger"

module.exports =
  class Worker
    @workload: 0
    @workLimit: 1000
    @terminate: false

    constructor: (@event) ->
      @event.on('draw', (matrix_json, next_line) => @attempt(matrix_json, next_line))

    #
    # @param {string} matrix_json
    # @param {LineKey} last_line
    #
    attempt: (matrix_json, curr_line) ->
      # ----------------
      # 強制終了
      return if Worker.terminate

      Worker.workload++
      if Worker.workload >= Worker.workLimit
        Worker.terminate = true
        @event.emit('not-solved', "Over work")
        return
      # ----------------

      Logger.headerInProgress("attempt with #{curr_line} ##{Worker.workload}")
      try
        matrix = Matrix.fromJson(matrix_json)
        matrix.drawLine(curr_line)

        # Violationが飛んでないので次のステップへ
        Logger.matrixInProgress(matrix)

        next_list = matrix.nextLines(curr_line)
        if next_list?
          Logger.messageInProgress("No violation, go ahead.\n")
          matrix_json = JSON.stringify(matrix)
          for next_line in next_list
            @event.emit('draw', matrix_json, next_line)
        else
          Logger.messageInProgress("Loop detected. check if it solved.\n")
          @checkSolved(matrix, curr_line)

      catch error
        if error instanceof Violation
          Logger.matrixInProgress(matrix)
          Logger.messageInProgress("#{error}\n")
        else
          throw error

    checkSolved: (matrix, last_line=null) ->
      unless matrix.isSatisfiedBoxValues()
        Logger.messageInProgress("Not satisfied all box value.\n")
        return false

      unless matrix.isAllLineInLoop(last_line)
        Logger.messageInProgress("Not one loop.\n")
        return false

      Worker.terminate = true
      @event.emit('solved', matrix)
      return true
