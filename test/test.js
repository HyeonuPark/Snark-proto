const {expect} = require('chai')
const fs = require('mz/fs')
const co = require('co')
const Path = require('path')
const snark = require('../lib/index')
const babel = require('babel-core')

const fixturePath = Path.resolve(__dirname, '.fixture')
const input = testName => Path.resolve(fixturePath, testName, 'input.snark')
const output = testName => Path.resolve(fixturePath, testName, 'output.js')

const fixtures = fs.readdirSync(fixturePath)

describe('.fixture', () => {
  for (let testName of fixtures) {
    it(testName, () => Promise.all([
      fs.readFile(input(testName), 'utf8'),
      fs.readFile(output(testName), 'utf8'),
    ]).then(([inputSrc, outputSrc]) => {
      const inputResult = snark.transform(inputSrc, {
        nobabel: true,
        noruntime: true,
        babelrc: false,
        compact: true,
        comments: false,
        ast: false
      }).code
      const outputResult = babel.transform(outputSrc, {
        babelrc: false,
        compact: true,
        comments: false,
        ast: false
      }).code

      if (inputResult !== outputResult) {
        throw new Error('Not matching')
      }
    }))
  }
})
