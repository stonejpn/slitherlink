{expect} = require "chai"
ConnectorPeer = require "../src/connector-peer"
Line = require "../src/line"

describe "ConnectorPeer", ->
  it "initialize 数を調べる", ->
    ConnectorPeer.initialize(3, 3)

    key_list = Object.keys(ConnectorPeer._peers)
    # 全部で24コ
    expect(key_list).to.have.lengthOf(24)

    # 重複なし
    uniq_list = key_list.filter((key, idx, list) -> list.indexOf(key) is idx)
    expect(uniq_list).to.have.lengthOf(24)

    # すべて要素が２つのArray
    expect(key_list.every(((key) -> @map[key].length is 2), {map: ConnectorPeer._peers})).to.be.true

  it "initialize 内容を調べる", ->
    ConnectorPeer.initialize(3, 3)

    line_key = 'v,2,1'
    to_be = [
      ['v,1,1', 'h,1,2', 'h,1,1']
      ['h,2,2', 'v,3,1', 'h,2,1']
    ]
    expect(ConnectorPeer._peers[line_key]).to.be.eql(to_be)

    # 隅っこ
    line_key = 'h,3,3'
    to_be = [
      ['v,3,3']
      ['v,3,2', 'h,3,2']
    ]
    expect(ConnectorPeer._peers[line_key]).to.eql(to_be)
