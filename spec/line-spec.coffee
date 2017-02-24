assert = require "assert"
Line = require "../src/line"

describe "Line", ->
  it "キーを作成", ->
    assert.equal(Line.horiz(1, 2), 'h,1,2')
