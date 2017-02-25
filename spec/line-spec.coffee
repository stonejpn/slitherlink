{expect} = require "chai"
Line = require "../src/line"

describe "Line", ->
  it "horiz/vert キーを作成", ->
    expect(Line.horiz(1, 2)).to.be.equal('h,1,2')
    expect(Line.vert(3, 4)).to.be.equal('v,3,4')

  it "countXXX ラインを数える", ->
    lines =
      'v,1,1': Line.DRAW
      'v.1,2': Line.DRAW
      'v.1,3': Line.DRAW
      'h,0,1': Line.BLOCK
      'h,0,2': Line.BLOCK
      'h,0,3': Line.UNDEFINED

    expect(Line.countDraw(lines)).to.be.equal(3)
    expect(Line.countBlock(lines)).to.be.equal(2)
    expect(Line.countUndefined(lines)).to.be.equal(1)

  it "all", ->
    expect(Line.all(4, 3)).to.be.lengthOf(31)
    key_list = Line.all(3, 3)
    expect(key_list).to.be.lengthOf(24)
    # ヨコのLine
    expect(key_list.filter((key) -> key.match(/^h/))).to.be.lengthOf(12)
    # タテのLine
    expect(key_list.filter((key) -> key.match(/^v/))).to.be.lengthOf(12)

  it "all コールバックあり", ->
    count = 0
    Line.all(3, 3, (key) -> count++)
    expect(count).to.equal(24)