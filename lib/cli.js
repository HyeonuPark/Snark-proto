const fs = require('fs')

const {transform} = require('./index')

const argv = require('minimist')(process.argv.slice(2))

const usage = () => console.log('Usage: \
$ snark-proto <input.snark> [-o <output.js>] [--nobabel]')

if (argv._.length !== 1) {
  usage()
} else {
  const input = argv._[0]
  const output = argv.o

  if (output === '.js') {
    usage()
  } else {
    fs.readFile(input, 'utf8', srcCode => {
      delete argv._
      delete argv.o
      const result = transform(srcCode, argv)

      if (output) {
        fs.writeFile(output, result.code, 'utf8')
      } else {
        process.stdout.write(result.code)
      }
    })
  }
}
