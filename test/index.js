const Path = require('path')
const fs = require('mz/fs')
const co = require('co')
const parser = require('../lib/index')
const babel = require('babel-core')

const fixture = Path.resolve(__dirname, '.fixture')

co(function* () {
  const fixtures = yield fs.readdir(fixture)
  const tests = yield Promise.all(fixtures.map(testName => Promise.all([
    fs.readFile(Path.resolve(fixture, testName, 'input.snark')),
    fs.readFile(Path.resolve(fixture, testName), 'output.js')
  ])))
})
