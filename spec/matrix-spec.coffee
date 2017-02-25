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

  it "clone", ->
    line_key = 'h,0,1'
    matrix.lines[line_key] = 'foo'

    child = matrix.clone()

    # 値が引き継がれている
    expect(child.lines[line_key]).to.be.equal('foo')

    matrix.lines[line_key] = 'bar'

    # 元のMatrixの値を変更しても、cloneには影響ない
    expect(child.lines[line_key]).to.be.equal('foo')

  it "parseGird Boxの値", ->
    matrix.parseGrid(sample_grid)
    expect(matrix.boxes['b,1,2']).to.be.equal(0)
    expect(matrix.boxes['b,1,3']).to.be.equal(1)
    expect(matrix.boxes['b,3,1']).to.be.equal(2)

  it "parseGrid ブロックされたLine", ->
    matrix.parseGrid(sample_grid)
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
      expect(matrix.lines[line_key]).to.be.equal(Line.BLOCK)

  describe "blockLine", ->
    [lineChanged] = []
    beforeEach ->
      lineChanged = sinon.stub(matrix, 'lineChanged')

    it "blockLine", ->
      matrix.lines[Line.horiz(0, 2)] = Line.BLOCK
      matrix.blockLine(Line.vert(1, 1))
      expect(matrix.lines[Line.vert(1, 1)]).to.be.equal(Line.BLOCK)

    it "blockLine LineViolationをthrowする", ->
      line_key = Line.horiz(0, 1)
      matrix.lines[line_key] = Line.DRAW
      expect(-> matrix.blockLine(line_key)).to.throw(Violation, Violation.Line)

  describe "drawLine", ->
    [lineChanged] = []

    beforeEach ->
      lineChanged = sinon.stub(matrix, 'lineChanged')

    it "LineViolationをthrowする", ->
      line_key = Line.horiz(1, 1)
      matrix.lines[line_key] = Line.DRAW
      expect(-> matrix.drawLine(line_key)).to.throw(Violation, Violation.Line)

      line_key = Line.horiz(0, 1)
      matrix.lines[line_key] = Line.BLOCK
      expect(-> matrix.drawLine(line_key)).to.throw(Violation, Violation.Line)

      line_key = Line.vert(2, 0)
      expect(-> matrix.drawLine(line_key)).not.to.throw(Violation, Violation.Line)

    it "DRAWに変更して、totalLineをインクリメント", ->
      line_key = Line.horiz(1, 1)
      matrix.drawLine(line_key)
      expect(matrix.lines[line_key]).to.be.equal(Line.DRAW)
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
      matrix.lines[line_key] = Line.DRAW
      matrix.lineChanged(line_key)
      expect(blockLine).to.have.been.calledWith(Line.horiz(0, 1))
      expect(blockLine).to.have.been.calledWith(Line.vert(1, 0))
      expect(blockLine).to.have.been.calledWith(Line.vert(1, 1))

    it "Boxの線が多すぎる", ->
      matrix.lines[Line.horiz(0, 1)] = Line.DRAW
      key = Line.horiz(1, 1)
      matrix.lines[key] = Line.DRAW
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Box)

    it "Boxのブロックが多すぎる", ->
      matrix.lines[Line.horiz(1, 1)] = Line.BLOCK
      matrix.lines[Line.vert(2, 0)] = Line.BLOCK
      key = Line.vert(2, 1)
      matrix.lines[key] = Line.BLOCK
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Box)

    it "Connector 2本引かれていたら他はブロックにする", ->
      matrix.lines[Line.horiz(2, 2)] = Line.DRAW
      key = Line.vert(2, 2)
      matrix.lines[key] = Line.DRAW
      matrix.lineChanged(key)

      expect(blockLine).to.have.been.calledWith(Line.horiz(2, 3))
      expect(blockLine).to.have.been.calledWith(Line.vert(3, 2))

    it "Connector 行き止まり", ->
      matrix.lines[Line.horiz(3, 2)] = Line.BLOCK
      matrix.lines[Line.horiz(3, 3)] = Line.BLOCK
      key = Line.vert(3, 2)
      matrix.lines[key] = Line.DRAW
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Connector)

    it "Connector 枝分かれ", ->
      matrix.lines[Line.horiz(3, 2)] = Line.DRAW
      matrix.lines[Line.horiz(3, 3)] = Line.DRAW
      key = Line.vert(3, 2)
      matrix.lines[key] = Line.DRAW
      expect(-> matrix.lineChanged(key)).to.throw(Violation, Violation.Connector)

  it "isConnected", ->
    key = Line.horiz(1, 3)
    expect(matrix.isConnected(key)).to.false

    matrix.lines[Line.vert(2, 2)] = Line.DRAW
    expect(matrix.isConnected(key)).to.false

    matrix.lines[Line.vert(2, 3)] = Line.DRAW
    expect(matrix.isConnected(key)).to.false

    matrix.lines[key] = Line.DRAW
    expect(matrix.isConnected(key)).to.true

  describe "inspectLoop", ->
    beforeEach ->
      matrix.parseGrid(sample_grid)

    it "すべてのBoxの値を満たしているか？", ->
      key = Line.horiz(1, 3)
      expect(-> matrix.inspectLoop(key)).to.throw(Violation, "LoopViolation: unsatisfied box value")

      matrix.lines[Line.horiz(1, 3)] = Line.DRAW
      matrix.lines[Line.horiz(3, 1)] = Line.DRAW
      matrix.lines[Line.vert(3, 0)] = Line.DRAW
      expect(-> matrix.inspectLoop(key)).not.to.throw("LoopViolation: unsatisfied box value")

    it "ループになっているか？", ->
      matrix.lines[Line.vert(2, 2)] = Line.DRAW
      matrix.lines[Line.horiz(1, 3)] = Line.DRAW
      matrix.lines[Line.vert(2, 3)] = Line.DRAW
      matrix.lines[Line.vert(3, 3)] = Line.DRAW
      matrix.lines[Line.horiz(3, 3)] = Line.DRAW
      matrix.lines[Line.horiz(3, 2)] = Line.DRAW
      matrix.lines[Line.horiz(3, 1)] = Line.DRAW
      matrix.lines[Line.vert(3, 0)] = Line.DRAW
      matrix.lines[Line.vert(2, 0)] = Line.DRAW
      expect(-> matrix.inspectLoop(Line.horiz(1, 3))).to.throw(Violation, "LoopViolation: not loop")

  describe "総合テスト", ->
    beforeEach ->
      matrix.parseGrid(sample_grid)

    it "正解の順路", ->
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
        expect(-> matrix.drawLine(key)).not.to.throw()

    it "行き止まりの順路", ->
      expect(-> matrix.drawLine(Line.vert(3, 1))).not.to.throw()
      expect(-> matrix.drawLine(Line.horiz(2, 1))).to.throw(Violation)
