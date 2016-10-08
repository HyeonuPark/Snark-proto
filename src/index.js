const babel = require('babel-core')
const babelOpt = require('./babel-option.json')
const parser = require('./parser')

exports.transform = function transform (code, userOpt) {
  const ast = parser.parse(code)
  const opt = Object.assign({}, userOpt.nobabel ? null : babelOpt, userOpt)
  return babel.transformAst(ast, code, opt)
}
