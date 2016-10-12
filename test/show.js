const Path = require('path')
const fs = require('mz/fs')
const co = require('co')
const snark = require('../lib/index')

const fixture = Path.resolve(__dirname, '.fixture')

if (process.argv.length <3) {
  console.log('Usage: $ npm run print <test name>')
  process.exit(0)
}
const target = process.argv[2]

co(function* () {
  const src = yield fs.readFile(Path.resolve(fixture, target, 'input.snark'), 'utf8')
  console.log('// input.snark\n')
  console.log(src)

  const output = snark.transform(src, {
    nobabel: true,
    noruntime: true,
    babelrc: false,
    compact: false,
    comments: false,
    ast: false
  })
  console.log('\n// output.js\n')
  console.log(output.code)
}).catch(err => console.log(err.stack, err))
