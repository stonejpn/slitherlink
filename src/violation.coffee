module.exports =
  class Violation
    @Line: 'LineViolation'
    @Box: 'BoxViolation'
    @Connector: 'ConnectorViolation'
    @Loop: 'LoopViolation'

    constructor: (@type, @message) ->

    toString: ->
      return "#{@type}: #{@message}"
