const Path = require('path')
const fs = require('mz/fs')
const co = require('co')
const peg = require('pegjs')

const toPeg = keywords => `
// Keywords
// Automatically generated from keywords.txt

ReservedKeywords
= ${keywords.map(key => `K_${key}`).join('\n/ ')}

${keywords.map(key => `
K_${key}
= '${key}' PD { return '${key}' }
`).join('').replace(/\n\n\n/g, '\n')}
`

co(function* () {
  const [parser, keywordsRaw, unicode] = yield Promise.all([
    'parser.pegjs',
    'keywords.txt',
    'unicode.pegjs',
  ].map(name => fs.readFile(Path.resolve(__dirname, name), 'utf8')))

  const keywords = toPeg(keywordsRaw.split('\n').slice(0, -1))

  const pegsrc = `${parser}\n${keywords}\n${unicode}`

  const result = peg.generate(pegsrc, {output: 'source'})

  yield fs.writeFile(Path.resolve(__dirname, 'parser.js'), result, 'utf8')

  console.log('Generated parser.js')
}).catch(err => {
  console.error(err.stack)
})
