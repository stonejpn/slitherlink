{expect} = require "chai"
Line = require "../src/line"
PeerMap = require "../src/peer-map"

describe "PeerMap", ->
  it "Create", ->
    lines =
      'v,1,1': Line.Draw
      'v.1,2': Line.Draw
      'v.1,3': Line.Draw
      'h,0,1': Line.Block
      'h,0,2': Line.Block
      'h,0,3': Line.ToBeFixed
    key_list = Object.keys(lines)

    to_be = new PeerMap()
    to_be.draw = ['v,1,1', 'v.1,2', 'v.1,3']
    to_be.block = ['h,0,1', 'h,0,2']
    to_be.to_be_fixed = ['h,0,3']

    expect(PeerMap.Create(key_list, lines)).to.be.eql(to_be)
