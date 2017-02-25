{expect} = require "chai"
Box = require "../src/box"

describe "Box", ->
  it "キーを作成", ->
    expect(Box.key(3, 5)).to.be.equal('b,3,5')

  it "#each() コールバックがないので、リストを返す", ->
    to_be = [
      'b,1,1', 'b,1,2', 'b,1,3'
      'b,2,1', 'b,2,2', 'b,2,3'
      'b,3,1', 'b,3,2', 'b,3,3'
    ]
    expect(Box.all(3, 3)).to.be.eql(to_be)

  it "#all() コールバックあり", ->
    count = 0
    Box.all(3, 3, (key) -> count++)
    expect(count).to.be.equal(9)
