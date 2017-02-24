module.exports =
  HORIZ: 'h'
  VERT: 'v'

  DRAW: 'd'
  BLOCK: 'x'
  UNDEFINED: null

  ###*
   * @typedef {string} LineKey
   * @typedef {string} LineStatus
  ###

  ###*
   * @return LineKey
  ###
  horiz: (row, col) ->
    "#{@HORIZ},#{row},#{col}"

  ###*
   * @return LineKey
  ###
  vert: (row, col) ->
    "#{@VERT},#{row},#{col}"

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countDraw: (lines) ->
    @_countInternal(lines, @DRAW)

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countBlock: (lines) ->
    @_countInternal(lines, @BLOCK)

  ###*
   * @param {Object.<LineKey, LineStatus>}
   * @return {LineKey[]}
  ###
  countUndefined: (lines) ->
    @_countInternal(lines, @UNDEFINED)

  _countInternal: (lines, status) ->
    Object.keys(lines).filter((key) -> lines[key] is status)
