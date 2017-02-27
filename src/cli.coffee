Solver = require "./solver"

# PUZZLE = '3x3:.01...2..'
# PUZZLE = '3x3:33.3.3.3.'
# PUZZLE = '10x10:......221..122..1.1..3.1..0.2..1.1..2.0..3.3..0.2..1.1..2.0..3.0..0.2..1.2..3.1..3.2..122..022......'
# PUZZLE = '10x10:.3..10..20.03..2....1......20..3..3....1......3..21..3......2....2..0..03......3....3..33.31..21..2.'
PUZZLE = '10x10:0........3..03.33.........0.3..33.....3..2..32........11..1..0.....20..3.0.........22.20..1........1'
# PUZZLE = '10x10:.3.3...3..30.12.0.3......3...232.31.1.3..1.2...2....1...1.3..1.3.22.210...2......3.3.22.32..2...0.3.'
# PUZZLE = '25x15:.3202...2313...23..20133330..31.30..31.321..31....32..12.23..22..32..11.......22..11..02..11..01122...22...02..32..23......22.32....22..12..02..31..22203103..1223..1122..0221...........................3122..3133..3212..31332212..31..11..31..22....12.12......02..32..31...22...30203..22..11..32..22.......32..30..22..22.32..12....21..323.30..12.31..13022221..31...2211...3221.'

start = Date.now()
Solver.run(PUZZLE, false)
spend_time = Date.now() - start
console.log("Time: #{spend_time / 1000} sec")
