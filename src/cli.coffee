Solver = require "./solver"
Worker = require "./worker"
program = require "commander"
app_package = require "../package.json"

process.stdin.setEncoding('utf8')

start = (puzzle, watch_in_progress) ->
  if puzzle.match(/^\d+x\d+:[\.0123]+$/)
    start = Date.now()
    Solver.run(puzzle, watch_in_progress)
    spend_time = Date.now() - start
    console.log("Time: #{spend_time / 1000} sec")
  else
    console.log("Input string is not match with puzzle format.")
  process.exit(0)

program
  .version(app_package.version)
  .usage("[-w] [-l limit] [puzzle]")
  .option('-w --watch', 'show all matrix in progress. (will output huge lines)')
  .option('-l --limit [limit]', 'limit of attempt (default:1000)', parseInt, 1000)
program.on('--help', ->
  console.log("  Puzzle example:  3x3:.01...2..")
  console.log("")
)
program.parse(process.argv)

if program.limit?
  Worker.workLimit = program.limit

puzzle = program.args.shift()


if puzzle?
  start(puzzle, program.watch)
else
  console.log("Please input puzzle. Format: <width>x<height>:<grid>")

  process.stdin.once('data', (user_input) ->
    # 最初の1行だけ
    puzzle = user_input.split(/\r?\n/)[0].replace(/^\s+/, '').replace(/\s+$/, '')
    start(puzzle, program.watch)
  )
