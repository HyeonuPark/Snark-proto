const fs = require('mz/fs')
const co = require('co')
const Path = require('path')
const snark = require('../lib/index')
const babel = require('babel-core')

const fixturePath = Path.resolve(__dirname, '.fixture')
const input = testName => Path.resolve(fixturePath, testName, 'input.snark')
const output = testName => Path.resolve(fixturePath, testName, 'output.js')

const fixtures = fs.readdirSync(fixturePath)

const notMatching = (dotSnark, dotJs) => `Not matching

// input.snark

${dotSnark}

// output.js

${dotJs}
`

describe('.fixture', () => {
  for (let testName of fixtures) {
    it(testName, () => Promise.all([
      fs.readFile(input(testName), 'utf8'),
      fs.readFile(output(testName), 'utf8'),
    ]).then(([inputSrc, outputSrc]) => {
      const inputResult = snark.transform(inputSrc, {
        nobabel: true,
        noruntime: true,
        compact: true,
        comments: false,
        ast: false
      }).code
      const outputResult = babel.transform(outputSrc, {
        compact: true,
        comments: false,
        ast: false
      }).code

      if (inputResult !== outputResult) {
        const inputLongResult = snark.transform(inputSrc, {
          nobabel: true,
          noruntime: true,
          compact: false,
          comments: false,
          ast: false
        }).code
        const outputLongResult = babel.transform(outputSrc, {
          compact: false,
          comments: false,
          ast: false
        }).code

        throw new Error(notMatching(inputLongResult, outputLongResult))
      }
    }))
  }
})
