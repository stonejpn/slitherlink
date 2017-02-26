Matrix = require "./matrix"
Violation = require "./violation"
Logger = require "./logger"

module.exports =
  class Worker
    @limiter: 0
    @terminate: false

    constructor: (@event) ->
      @event.on('next', (matrix, last_line) => @attempt(matrix, last_line))

    #
    # @param {Matrix} matrix
    # @param {LineKey} last_line
    #
    attempt: (matrix, last_line=null) ->
      return if Worker.terminate

      Worker.limiter++
      if Worker.limiter >= 10000
        Worker.terminate = true
        @event.emit('not-solved', "Over attempt limiter")
        return

      next_list = null
      if last_line?
        next_list = matrix.nextLines(last_line)
      else
        next_list = matrix.findStartList()

      if next_list is null
        # next_lineがnull -> ループが形成されている
        # 解けているか、間違ったループかのどちらか
        @checkSolved(matrix, last_line)
        return

      Logger.headerInProgress("attempt with #{last_line} #{Worker.limiter}")

      matrix_json = JSON.stringify(matrix)
      for line_key in next_list
        return if Worker.terminate

        m = Matrix.fromJson(matrix_json)
        try
          m.drawLine(line_key)
          Logger.matrixInProgress(m, "draw line #{line_key}")

          @event.emit('next', m, line_key)
        catch error
          if error instanceof Violation
            Logger.matrixInProgress(m)
            Logger.messageInProgress("#{error}")
          else
            throw error

    checkSolved: (matrix, last_line) ->
      if matrix.isSatisfiedBoxValues(last_line)
        Worker.terminate = true
        @event.emit('solved', matrix)
      else
        Logger.messageInProgress("Not satisfied all box value.\n")
