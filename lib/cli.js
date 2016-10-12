const fs = require('fs')

const {transform} = require('./index')

const argv = require('minimist')(process.argv.slice(2))

const usage = () => console.log('Usage: \
$ snark-proto <source>.snark [-o <source>.js] [--nobabel]')

if (argv._.length !== 1) {
  usage()
} else {
  const input = argv._[0]
  const output = argv.o || input.split('.').slice(0, -1).join('.') + '.js'

  if (output === '.js') {
    usage()
  } else {
    fs.readFile(input, 'utf8', srcCode => {
      delete argv._
      delete argv.o
      const {code: jsCode} = transform(srcCode, argv)

      fs.writeFile(output, jsCode, 'utf8')
    })
  }
}
