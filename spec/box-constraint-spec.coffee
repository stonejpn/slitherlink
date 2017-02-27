chai = require "chai"
expect = chai.expect

sinon = require "sinon"
chai.use(require "sinon-chai")

BoxConstraint = require "../src/box-constraint"
Matrix = require "../src/matrix"
Line = require "../src/line"
Box = require "../src/box"
BoxPeer = require "../src/box-peer"
ConnectorPeer = require "../src/connector-peer"

describe "BoxConstraint", ->
  [matrix, drawLine, blockLine] = []

  beforeEach ->
    ConnectorPeer.initialize(3, 3)
    BoxPeer.initialize(Box.all(3, 3))

    matrix = new Matrix(3, 3)
    drawLine = sinon.stub(matrix, "drawLine")
    blockLine = sinon.stub(matrix, "blockLine")

  describe "constraint0", ->
    it "値が0のBoxの周りをブロック", ->
      matrix.parseGrid('....0....')
      to_be_blocked = [
        Line.horiz(1, 2)
        Line.vert(2, 2)
        Line.horiz(2, 2)
        Line.vert(2, 1)
      ]
      BoxConstraint.constraint0(matrix, 3, 3)

      for line_key in to_be_blocked
        expect(blockLine).to.have.been.calledWith(line_key)

  describe "constraint3", ->
    it "左右で隣同士", ->
      matrix.parseGrid('....33...')
      to_be_drawn = [
        Line.vert(2, 1)
        Line.vert(2, 2)
        Line.vert(2, 3)
      ]
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "上下で隣同士", ->
      matrix.parseGrid('....3..3.')
      to_be_drawn = [
        Line.horiz(1, 2)
        Line.horiz(2, 2)
        Line.horiz(3, 2)
      ]
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)


    it "斜め左下も3", ->
      matrix.parseGrid('.3.3.....')
      to_be_drawn = [
        Line.horiz(0, 2)
        Line.vert(1, 2)
        Line.vert(2, 0)
        Line.horiz(2, 1)
      ]
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "斜め右下も3", ->
      matrix.parseGrid('...3...3.')
      to_be_drawn = [
        Line.horiz(1, 1)
        Line.vert(2, 0)
        Line.vert(3, 2)
        Line.horiz(3, 2)
      ]
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "斜め左上が0", ->
      to_be_drawn = [
        Line.horiz(2, 2)
        Line.vert(3, 1)
      ]
      matrix.parseGrid('...0...3.')
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "ななめ右上が0", ->
      to_be_drawn = [
        Line.horiz(2, 2)
        Line.vert(3, 2)
      ]
      matrix.parseGrid('.....0.3.')
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "左ななめ下が0", ->
      to_be_drawn = [
        Line.vert(1, 1)
        Line.horiz(1, 2)
      ]
      matrix.parseGrid('.3.0.....')
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "右ななめ下が0", ->
      to_be_drawn = [
        Line.vert(1, 2)
        Line.horiz(1, 2)
      ]
      matrix.parseGrid('.3...0...')
      BoxConstraint.constraint3(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

  describe "corners", ->
    it "値が1のとき", ->
      to_be_blocked = [
        Line.horiz(0, 1)
        Line.vert(1, 0)
        Line.horiz(0, 3)
        Line.vert(1, 3)
        Line.horiz(3, 1)
        Line.vert(3, 0)
        Line.horiz(3, 3)
        Line.vert(3, 3)
      ]
      matrix.parseGrid('1.1...1.1')
      BoxConstraint.corners(matrix, 3, 3)
      for line_key in to_be_blocked
        expect(blockLine).to.have.been.calledWith(line_key)

    it "値が2のとき 左上＋右下", ->
      to_be_drawn = [
        Line.horiz(0, 2)
        Line.vert(2, 0)
        Line.vert(2, 3)
        Line.horiz(3, 2)
      ]
      matrix.parseGrid('2.......2')
      BoxConstraint.corners(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "値が2のとき 右上＋左下", ->
      to_be_drawn = [
        Line.horiz(0, 2)
        Line.vert(2, 3)
        Line.horiz(3, 2)
        Line.vert(2, 0)
      ]
      matrix.parseGrid('..2...2..')
      BoxConstraint.corners(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

    it "値が3の時", ->
      to_be_drawn = [
        Line.horiz(0, 1)
        Line.vert(1, 0)
        Line.horiz(0, 3)
        Line.vert(1, 3)
        Line.horiz(3, 1)
        Line.vert(3, 0)
        Line.horiz(3, 3)
        Line.vert(3, 3)
      ]
      matrix.parseGrid('3.3...3.3')
      BoxConstraint.corners(matrix, 3, 3)
      for line_key in to_be_drawn
        expect(drawLine).to.have.been.calledWith(line_key)

