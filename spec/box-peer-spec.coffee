{expect} = require "chai"
BoxPeer = require "../src/box-peer"

describe "BoxPeer", ->
  [box_list] = []

  beforeEach ->
    box_list = [
      'b,1,1', 'b,1,2', 'b,1,3'
      'b,2,1', 'b,2,2', 'b,2,3'
      'b,3,1', 'b,3,2', 'b,3,3'
    ]

  it "initialize _lines", ->
    BoxPeer.initialize(box_list)

    expect(Object.keys(BoxPeer._lines)).to.have.lengthOf(9)

    to_be = ['h,1,1', 'v,2,1', 'h,2,1', 'v,2,0']
    expect(BoxPeer._lines['b,2,1']).to.eql(to_be)

  it "initialize _boxes", ->
    BoxPeer.initialize(box_list)

    expect(Object.keys(BoxPeer._boxes)).to.have.lengthOf(24)

    to_be = ['b,1,2']
    expect(BoxPeer._boxes['h,0,2']).to.eql(to_be)

    to_be = ['b,2,2', 'b,2,3']
    expect(BoxPeer._boxes['v,2,2']).to.eql(to_be)

  it "getBoxes", ->
    to_be = ['b,2,3', 'b,3,3']
    expect(BoxPeer.getBoxes('h,2,3')).to.eql(to_be)

  it "getPeer", ->
    to_be = ['h,2,2', 'v,3,2', 'h,3,2', 'v,3,1']
    expect(BoxPeer.getPeer('b,3,2')).to.eql(to_be)
