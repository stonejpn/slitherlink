chai = require "chai"
expect = chai.expect

sinon = require "sinon"
chai.use(require "sinon-chai")

Matrix = require "../src/matrix"
Line = require "../src/line"
Box = require "../src/box"
Violation = require "../src/violation"

describe "Matrix", ->
  [matrix, sample_grid] = []

  beforeEach ->
    matrix = new Matrix(3, 3)
    sample_grid = '.01...2..' # 3x3

  it "fromJson", ->
    matrix.parseGrid(sample_grid).evalBoxValues()
    json_str = JSON.stringify(matrix)
    expect(Matrix.fromJson(json_str)).to.be.eql(matrix)

  it "countXXX ラインを数える", ->
    matrix.lines =
      'v,1,1': Line.Draw
      'v.1,2': Line.Draw
      'v.1,3': Line.Draw
      'h,0,1': Line.Block
      'h,0,2': Line.Block
      'h,0,3': Line.ToBeFixed
    key_list = Object.keys(matrix.lines)

    expect(matrix.countDraw(key_list)).to.be.equal(3)
    expect(matrix.countBlock(key_list)).to.be.equal(2)
    expect(matrix.countUndefined(key_list)).to.be.equal(1)

  it "parseGird Boxの値", ->
    matrix.parseGrid(sample_grid)
    expect(matrix.boxes['b,1,2']).to.be.equal(0)
    expect(matrix.boxes['b,1,3']).to.be.equal(1)
    expect(matrix.boxes['b,3,1']).to.be.equal(2)

  describe "evalBoxValues", ->
    it "ブロックされたLine", ->
      matrix.parseGrid(sample_grid).evalBoxValues()
      block_list = [
        Line.horiz(0, 2)
        Line.vert(1, 2)
        Line.horiz(1, 2)
        Line.vert(1, 1)
        Line.horiz(0, 1)
        Line.vert(1, 0)
        Line.horiz(0, 3)
        Line.vert(1, 3)
      ]
      for line_key in block_list
        expect(matrix.lines[line_key]).to.be.equal(Line.Block)

    it "DrawされたLine", ->
      matrix.parseGrid(sample_grid).evalBoxValues()

      # 不要なDraw/Block伝搬を防ぐため、lineChangedはstub化する
      sinon.stub(matrix, 'lineChanged')
      expect(matrix.lines[Line.horiz(1, 3)]).to.be.equal(Line.Draw)

  describe "blockLine", ->
    [lineChanged] = []
    beforeEach ->
      lineChanged = sinon.stub(matrix, 'lineChanged')

    it "blockLine", ->
      matrix.lines[Line.horiz(0, 2)] = Line.Block
      matrix.blockLine(Line.vert(1, 1))
      expect(matrix.lines[Line.vert(1, 1)]).to.be.equal(Line.Block)

    it "blockLine LineViolationをthrowする", ->
      line_key = Line.horiz(0, 1)
      matrix.lines[line_key] = Line.Draw
      expect(-> matrix.blockLine(line_key)).to.throw(Violation, Violation.Line)

  describe "drawLine", ->
    [lineChanged] = []

    beforeEach ->
      lineChanged = sinon.stub(matrix, 'lineChanged')

    it "LineViolationをthrowする", ->
      line_key = Line.horiz(1, 1)
      matrix.lines[line_key] = Line.Draw
      expect(-> matrix.drawLine(line_key)).to.throw(Violation, Violation.Line)

      line_key = Line.horiz(0, 1)
      matrix.lines[line_key] = Line.Block
      expect(-> matrix.drawLine(line_key)).to.throw(Violation, Violation.Line)

      line_key = Line.vert(2, 0)
      expect(-> matrix.drawLine(line_key)).not.to.throw(Violation, Violation.Line)

    it "DRAWに変更して、totalLineをインクリメント", ->
      line_key = Line.horiz(1, 1)
      matrix.drawLine(line_key)
      expect(matrix.lines[line_key]).to.be.equal(Line.Draw)
      expect(matrix).to.have.property('totalLine', 1)

    it "lineChanged()がコールされる", ->
      line_key = Line.horiz(1, 1)
      matrix.drawLine(line_key)
      expect(lineChanged).to.have.been.calledWith(line_key)

  describe "lineChanged", ->
    [blockLine] = []

    beforeEach ->
      matrix = new Matrix(3, 3)
      matrix.boxes[Box.key(1, 1)] = 1
      matrix.boxes[Box.key(2, 1)] = 2
      blockLine = sinon.stub(matrix, 'blockLine')

    it "追加でBLOCKされるラインが出てくる", ->
      line_key = Line.horiz(1, 1)
      matrix.lines[line_key] = Line.Draw
      matrix.lineChanged(line_key)
      expect(blockLine).to.have.been.calledWith(Line.horiz(0, 1))
      expect(blockLine).to.have.been.calledWith(Line.vert(1, 0))
      expect(blockLine).to.have.been.calledWith(Line.vert(1, 1))

    it "Boxの線が多すぎる", ->
      matrix.lines[Line.horiz(0, 1)] = Line.Draw
      key = Line.horiz(1, 1)
      matrix.lines[key] = Line.Draw
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Box)

    it "Boxのブロックが多すぎる", ->
      matrix.lines[Line.horiz(1, 1)] = Line.Block
      matrix.lines[Line.vert(2, 0)] = Line.Block
      key = Line.vert(2, 1)
      matrix.lines[key] = Line.Block
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Box)

    it "Connector 2本引かれていたら他はブロックにする", ->
      matrix.lines[Line.horiz(2, 2)] = Line.Draw
      key = Line.vert(2, 2)
      matrix.lines[key] = Line.Draw
      matrix.lineChanged(key)

      expect(blockLine).to.have.been.calledWith(Line.horiz(2, 3))
      expect(blockLine).to.have.been.calledWith(Line.vert(3, 2))

    it "Connector 行き止まり", ->
      matrix.lines[Line.horiz(3, 2)] = Line.Block
      matrix.lines[Line.horiz(3, 3)] = Line.Block
      key = Line.vert(3, 2)
      matrix.lines[key] = Line.Draw
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Connector)

    it "Connector 枝分かれ", ->
      matrix.lines[Line.horiz(3, 2)] = Line.Draw
      matrix.lines[Line.horiz(3, 3)] = Line.Draw
      key = Line.vert(3, 2)
      matrix.lines[key] = Line.Draw
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Connector)

  describe "isSatisfiedBoxValues", ->
    beforeEach ->
      matrix.parseGrid(sample_grid)

    it "満たしてない", ->
      expect(matrix.isSatisfiedBoxValues(Line.horiz(1, 3))).to.be.false

    it "一応満たしてる", ->
      matrix.lines[Line.horiz(1, 3)] = Line.Draw
      matrix.lines[Line.horiz(3, 1)] = Line.Draw
      matrix.lines[Line.vert(3, 0)] = Line.Draw
      expect(matrix.isSatisfiedBoxValues(Line.horiz(1, 3))).to.be.true

  describe "nextLines", ->
    it "ループになってない", ->
      matrix.lines[Line.vert(2, 2)] = Line.Draw
      matrix.lines[Line.horiz(1, 3)] = Line.Draw
      matrix.lines[Line.vert(2, 3)] = Line.Draw

      to_be = [Line.vert(3, 3), Line.horiz(2, 3)]
      expect(matrix.nextLines(Line.horiz(1, 3))).to.be.eql(to_be)

      to_be = [Line.vert(3, 3), Line.horiz(2, 3)]
      expect(matrix.nextLines(Line.vert(2, 3))).to.be.eql(to_be)

    it "ループになってる", ->
      matrix.lines[Line.vert(2, 2)] = Line.Draw
      matrix.lines[Line.horiz(1, 3)] = Line.Draw
      matrix.lines[Line.vert(2, 3)] = Line.Draw
      matrix.lines[Line.vert(3, 3)] = Line.Draw
      matrix.lines[Line.horiz(3, 3)] = Line.Draw
      matrix.lines[Line.vert(3, 2)] = Line.Draw
      expect(matrix.nextLines(Line.horiz(1, 3))).to.be.null

  describe "findStartList", ->
    it "Drawが1つもないケース", ->
      matrix = new Matrix(2, 2)
      matrix.parseGrid('22..').evalBoxValues()
      to_be = ['h,0,1', 'v,1,1', 'h,1,1', 'v,1,0']

      expect(matrix.findStartList()).to.be.eql(to_be)

    it "Drawが１つはあるケース", ->
      matrix.parseGrid(sample_grid).evalBoxValues()
      to_be = ['v,3,3', 'h,2,3']

      expect(matrix.findStartList()).to.be.eql(to_be)

    it "ループしてるケース", ->
      # evalBoxValues()の段階で、解けているケース
      matrix.parseGrid(sample_grid).evalBoxValues()
      key = Line.horiz(2, 3)
      matrix.lines[key] = Line.Draw

      expect(matrix.findStartList()).to.be.null

  describe "総合テスト", ->
    beforeEach ->
      matrix.parseGrid(sample_grid).evalBoxValues()

    it.skip "正解の順路", ->
      route = [
        Line.horiz(1, 3)
        Line.vert(2, 3)
        Line.vert(3, 3)
        Line.horiz(3, 3)
        Line.horiz(3, 2)
        Line.horiz(3, 1)
        Line.vert(3, 0)
        Line.vert(2, 0)
        Line.horiz(1, 1)
        Line.vert(2, 1)
        Line.horiz(2, 2)
        Line.vert(2, 2)
      ]
      for key in route
        # 何もおきない
        expect(-> matrix.drawLine(key)).not.to.throw("Violation")

    it "行き止まりの順路", ->
      expect(-> matrix.drawLine(Line.vert(3, 1))).not.to.throw()
      expect(-> matrix.drawLine(Line.horiz(2, 1))).to.throw(Violation)
