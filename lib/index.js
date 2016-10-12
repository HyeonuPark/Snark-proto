const babel = require('babel-core')
const babelOpt = require('./babelrc.json')
const parser = require('../bin/parser')

exports.transform = function transform (code, userOpt) {
  const ast = parser.parse(code)
  if (userOpt.noruntime) {
    ast.program.body.splice(ast.program.runtimeStart, ast.program.runtimeLength)
  }
  const opt = Object.assign({}, userOpt.nobabel ? null : babelOpt, userOpt)
  delete opt.nobabel
  delete opt.noruntime
  return babel.transformFromAst(ast, code, opt)
}
