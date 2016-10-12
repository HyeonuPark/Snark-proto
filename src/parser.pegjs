{
  function Node (type, data) {
    const {start, end} = location()

    return Object.assign({
      type,
      start: start.offset,
      end: end.offset,
      loc: {
        start: {
          line: start.line,
          column: start.column - 1,
        },
        end: {
          line: end.line,
          column: end.column - 1,
        },
      },
    }, data)
  }

  function SubNode(type, data) {
    return Object.assign({type}, data)
  }

  function take (array, index) {
    return array.map(el => el[index])
  }

  function list (head, tail) {
    return [head, ...take(tail, 1)]
  }

  function loadJSSymbol (name) {
    return SubNode('VariableDeclarator', {
      id: SubNode('Identifier', {name: `symbol_${name}_`}),
      init: SubNode('MemberExpression', {
        object: SubNode('Identifier', {name: 'Symbol'}),
        property: SubNode('Identifier', {name}),
        computed: false
      })
    })
  }

  function loadSnarkSymbol (name) {
    return SubNode('VariableDeclarator', {
      id: SubNode('Identifier', {name: `symbol_${name}_`}),
      init: SubNode('MemberExpression', {
        object: SubNode('MemberExpression', {
          object: SubNode('Identifier', {name: 'snarkRuntime'}),
          property: SubNode('Identifier', {name: 'symbol'}),
          computed: false
        }),
        property: SubNode('Identifier', {name}),
        computed: false
      })
    })
  }

  function dedent (lines) {
    const indent = lines
      .map(l => l.line)
      .map(l => l.length - l.replace(/^\s*/, '').length)
      .reduce((left, right) => Math.min(left, right))

    return lines.map(l => l.line.slice(indent) + l.end).join('')
  }
}

File
= hashbang:Hashbang? WL program:Program WL {
  return Node('File', {hashbang, program})
}

Hashbang
= '#!' content:$((!LineBreakSequence .)*) LineBreakSequence {
  return content
}

Program
= importBlock:ImportBlock WL statementBlock:RootLevelStatementBlock {
  const initRuntime = [
    SubNode('ImportDeclaration', {
      specifiers: [],
      source: SubNode('StringLiteral', {value: 'snark-runtime'})
    }),
    SubNode('VariableDeclaration', {
      kind: 'let',
      declarations: [
        SubNode('VariableDeclarator', {
          id: SubNode('Identifier', {name: '_'}),
          init: null
        })
      ]
    }),
    SubNode('VariableDeclaration', {
      kind: 'const',
      declarations: [
        loadJSSymbol('iterator'),
        loadJSSymbol('match'),
        loadJSSymbol('replace'),
        loadJSSymbol('search'),
        loadJSSymbol('split'),
        loadJSSymbol('hasInstance'),
        loadJSSymbol('isConcatSpreadable'),
        loadJSSymbol('unscopable'),
        loadJSSymbol('species'),
        loadJSSymbol('toPrimitive'),
        loadJSSymbol('toStringTag'),
        loadJSSymbol('asyncIterator'),
        loadSnarkSymbol('get'),
        loadSnarkSymbol('set'),
        loadSnarkSymbol('exec'),
        SubNode('VariableDeclarator', {
          id: SubNode('Identifier', {name: 'symbol_proto_'}),
          init: SubNode('StringLiteral', {value: '__proto__'})
        }),
        SubNode('VariableDeclarator', {
          id: SubNode('Identifier', {name: 'generator_wrapper_'}),
          init: SubNode('MemberExpression', {
            object: SubNode('Identifier', {name: 'snarkRuntime'}),
            property: SubNode('Identifier', {name: 'generatorWrapper'}),
            computed: false
          })
        }),
        SubNode('VariableDeclarator', {
          id: SubNode('Identifier', {name: 'range_'}),
          init: SubNode('MemberExpression', {
            object: SubNode('Identifier', {name: 'snarkRuntime'}),
            property: SubNode('Identifier', {name: 'range'}),
            computed: false
          })
        })
      ]
    })
  ]

  return Node('Program', {
    sourceType: 'module',
    body: [...importBlock, ...initRuntime, ...statementBlock],
    directives: [],
    runtimeStart: importBlock.length,
    runtimeLength: initRuntime.length
  })
}

ImportBlock
= head:ImportClause tail:(StrongSep ImportClause)* {
  return list(head, tail)
}
/ WL {
  return []
}

RootLevelStatementBlock
= head:RootLevelStatement tail:(StrongSep RootLevelStatement)* {
  return list(head, tail)
}
/ WL {
  return []
}

RootLevelStatement
= Statement
/ ExportClause

Statement
= AssignmentStatement
/ DeclarationStatement
/ FunctionStatement
/ IfStatement
/ WhileStatement
/ ForOfStatement
/ BreakStatement
/ ContinueStatement
/ ReturnStatement
/ ThrowStatement
/ EnumStatement
/ expression:Expression {
  return Node('ExpressionStatement', {expression})
}

AssignmentStatement
= left:AssignmentPattern PD '=' PD right:Expression {
  return Node('ExpressionStatement', {
    expression: Node('AssignmentExpression', {left, right, operator: '='})
  })
}
/ left:AssignmentTargetExpression PD operator:AssignmentOperator PD right:Expression {
  return Node('ExpressionStatement', {
    expression: Node('AssignmentExpression', {left, right, operator})
  })
}

AssignmentTargetExpression
= Identifier
/ obj:Expression prop:ObjectPropertyClause {
  return prop(obj)
}

AssignmentOperator
= $([\+\-\*\/] '=')
/ '='

DeclarationStatement
= K_let isMut:K_mut? id:AssignmentPattern PD '=' PD init:Expression {
  return Node('VariableDeclaration', {
    kind: isMut ? 'let' : 'const',
    declarations: [SubNode('VariableDeclarator', {id, init})]
  })
}

IfStatement
= K_if test:Expression PD consequent:StatementBlock orelse:(WL K_else StatementBlock) {
  return Node('IfStatement', {test, consequent, alternate: orelse && orelse[2]})
}

WhileStatement
= K_while test:Expression PD body:StatementBlock {
  return Node('WhileStatement', {test, body})
}

ForOfStatement
= K_for isAsync:K_await? id:AssignmentPattern PD right:Expression PD body:StatementBlock {
  body.body.unshift(SubNode('VariableDeclaration', {
    kind: 'const',
    declarations: [SubNode('VariableDeclarator', {
      id,
      init: SubNode('Identifier', {name: 'iter_each_'})
    })]
  }))

  return Node('ForOfStatement', {
    left: SubNode('VariableDeclaration', {
      kind: 'let',
      declarations: [SubNode('VariableDeclarator', {
        id: SubNode('Identifier', {name: 'iter_each_'})
      })]
    }),
    right,
    body
  })
}

BreakStatement
= K_break {
  return Node('BreakStatement')
}

ContinueStatement
= K_continue {
  return Node('ContinueStatement')
}

ReturnStatement
= K_return argument:Expression? {
  return Node('ReturnStatement', {argument})
}

ThrowStatement
= K_throw argument:Expression {
  return Node('ThrowStatement', {argument})
}

EnumStatement
= K_enum name:Identifier PD '{' WL head:Identifier tail:(StrongSep Identifier)* WL '}' {
  const elements = list(head, tail)

  return Node('VariableDeclaration', {
    kind: 'const',
    declarations: [
      ...elements.map(id => SubNode('VariableDeclarator', {
        id,
        init: SubNode('StringLiteral', {value: id.name})
      })),
      SubNode('VariableDeclarator', {
        id: name,
        init: SubNode('ArrayExpression', {elements})
      })
    ]
  })
}

Expression
= LogicalBinaryExpression

LogicalBinaryExpression
= head:LogicalNegateExpression tail:(PD (K_and / K_or) LogicalNegateExpression)* {
  return tail.reduce((left, [, op, right]) => Node('LogicalExpression', {
    operator: op === 'and' ? '&&' : '||',
    left,
    right
  }), head)
}

LogicalNegateExpression
= K_not argument:RangeExpression {
  return Node('UnaryExpression', {
    operator: '!',
    prefix: true,
    argument
  })
}
/ RangeExpression

// TODO: PatternInExpression

RangeExpression
= left:ArithmeticExpression PD leftExclude:'<'? '~' rightExclude:'<'? right:ArithmeticExpression {
  const toBool = arg => arg
    ? SubNode('BooleanLiteral', {value: true})
    : SubNode('BooleanLiteral', {value: false})

  return Node('CallExpression', {
    callee: SubNode('Identifier', {name: 'range_'}),
    arguments: [
      left,
      right,
      toBool(leftExclude),
      toBool(rightExclude)
    ]
  })
}
/ ArithmeticExpression

ArithmeticExpression
= ArithmeticL3Expression

ArithmeticL3Expression
= head:ArithmeticL2Expression tail:(PD ('**') PD ArithmeticL2Expression)* {
  return tail.reduce((left, [, operator, , right]) => Node('BinaryExpression', {
    operator,
    left,
    right
  }), head)
}

ArithmeticL2Expression
= head:ArithmeticL1Expression tail:(PD ('*' / '/') PD ArithmeticL1Expression)* {
  return tail.reduce((left, [, operator, , right]) => Node('BinaryExpression', {
    operator,
    left,
    right
  }), head)
}

ArithmeticL1Expression
= head:SuspensionExpression tail:(PD ('+' / '-') PD SuspensionExpression)* {
  return tail.reduce((left, [, operator, , right]) => Node('BinaryExpression', {
    operator,
    left,
    right
  }), head)
}

// TODO: AliasExpression

SuspensionExpression
= kind:(K_yield / K_await) star:('*' PD)? expr:Expression {
  const keyword = star ? `${kind}*` : kind

  return Node('YieldExpression', {
    delegate: false,
    argument: SubNode('ArrayExpression', {
      elements: [
        SubNode('StringLiteral', {value: keyword}),
        expr
      ]
    })
  })
}
/ ChainExpression

ChainExpression
= head:LiteralExpression tail:ChainElement* {
  return tail.reduce((left, right) => right(left), head)
}

ChainElement
= FunctionCallClause
/ ObjectPropertyClause
/ VirtualMethodClause
/ CollectionSetterClause
/ CollectionGetterClause

FunctionCallClause
= PD '(' WL head:ListElement tail:(WeakSep ListElement)* WL ')' {
  return callee => Node('CallExpression', {callee, arguments: list(head, tail)})
}

ObjectPropertyClause
= WL '.' PD property:PublicIdentifier {
  return object => Node('MemberExpression', {
    object,
    property,
    computed: false
  })
}
/ WL '.' PD prop:PrivateIdentifier {
  return object => Node('MemberExpression', {
    object,
    property: prop.innerExpression,
    computed: true
  })
}

VirtualMethodClause
= WL '::' PD K_new '(' WL head:ListElement tail:(WeakSep ListElement)* WL ')' {
  return callee => Node('NewExpression', {callee, arguments: list(head, tail)})
}
/ WL '::' PD callee:PublicIdentifier {
  return object => Node('BindExpression', {object, callee})
}
/ WL '::' PD cl:PrivateIdentifier {
  return object => Node('BindExpression', {object, callee: cl.innerExpression})
}

CollectionSetterClause
= PD '[' WL key:Expression WL '->' WL value:Expression WL ']' {
  return object => Node('CallExpression', {
    callee: SubNode('MemberExpression', {
      object,
      property: SubNode('Identifier', {name: 'symbol_set_'}),
      computed: true
    }),
    arguments: [key, value]
  })
}

CollectionGetterClause
= PD '[' WL key:Expression WL ']' {
  return object => Node('CallExpression', {
    callee: SubNode('MemberExpression', {
      object,
      property: SubNode('Identifier', {name: 'symbol_get_'}),
      computed: true
    }),
    arguments: [key]
  })
}

LiteralExpression
= KeywordLiteral
/ SwitchLiteral
/ DoLiteral
/ NumberLiteral
/ StringLiteral
// TemplateLiteral
/ ObjectLiteral
/ ArrayLiteral
/ FunctionLiteral
/ Identifier
/ '(' WL expr:Expression WL ')' {
  return expr
}

KeywordLiteral
= K_null {
  return Node('NullLiteral')
}
/ K_true {
  return Node('BooleanLiteral', {value: true})
}
/ K_false {
  return Node('BooleanLiteral', {value: false})
}
/ K__ {
  return Node('UnaryExpression', {
    operator: 'void',
    prefix: true,
    argument: SubNode('NumericLiteral', {value: 0})
  })
}

SwitchLiteral
= K_switch arg:Expression PD '{' WL head:SwitchBranch tail:(StrongSep SwitchBranch) WL '}' {
  return list(head, tail).reduceRight((alternate, {cond, expr}) => (
    Node('ConditionalExpression', {
      test: SubNode('BinaryExpression', {
        operator: '===',
        left: arg,
        right: cond
      }),
      consequent: expr,
      alternate
    })
  ), SubNode('NullLiteral'))
}
/ K_switch '{' WL head:SwitchBranch tail:(StrongSep SwitchBranch) WL '}' {
  return list(head, tail).reduceRight((alternate, {cond, expr}) => (
    Node('ConditionalExpression', {
      test: cond,
      consequent: expr,
      alternate
    })
  ))
}

SwitchBranch
= cond:Expression PD '->' PD expr:Expression {
  return {cond, expr}
}

DoLiteral
= keyword:(K_do / K_async) star:('*' PD)? body:StatementBlock {
  if (keyword === 'do' && !star) return Node('CallExpression', {
    callee: SubNode('FunctionExpression', {
      id: null,
      params: [],
      generator: false,
      async: false,
      body
    }),
    arguments: [],
  })

  return Node('CallExpression', {
    callee: SubNode('Identifier', {name: 'generator_wrapper_'}),
    arguments: [
      SubNode('FunctionExpression', {
        id: null,
        params: [],
        generator: true,
        async: false,
        body
      }),
      keyword === 'do' ? 'do' : star ? 'async*' : 'async'
    ]
  })
}

NumberLiteral
= HexNumber
/ OctalNumber
/ BinaryNumber
/ DecimalNumber

DecimalNumber
= left:Integer '.' right:Integer exponent:ExponentPart? {
  return Node('NumericLiteral', {
    value: parseFloat(`${left}.${right}${exponent || ''}`)
  })
}
/ num:Integer exponent:ExponentPart? {
  return Node('NumericLiteral', {
    value: parseInt(`${num}${exponent || ''}`, 10)
  })
}

ExponentPart
= [Ee] num:Integer {
  return `e${num}`
}

Integer
= num:$(!'_' ('_'? [0-9])+) {
  return num.replace(/_/g, '')
}

HexNumber
= '0' [Xx] num:$(!'_' ('_'? [0-9a-fA-F])+) {
  return Node('NumericLiteral', {value: parseInt(num.replace(/_/g, ''), 16)})
}

OctalNumber
= '0' [Oo] num:$(!'_' ('_'? [0-7]+)) {
  return Node('NumericLiteral', {value: parseInt(num.replace(/_/g, ''), 8)})
}

BinaryNumber
= '0' [Bb] num:$(!'_' ('_'? [01]+)) {
  return Node('NumericLiteral', {value: parseInt(num.replace(/_/g, ''), 2)})
}

StringLiteral
= "'''" LineBreakSequence content:StringLine* [\s]* "'''" {
  return Node('StringLiteral', {value: dedent(content)})
}
/ "'" content:StringCharacter* "'" {
  return Node('StringLiteral', {value: content.join('')})
}

StringLine
= content:StringCharacter* end:LineBreakSequence {
  return {line: content.join(''), end}
}

StringCharacter
= !("'" / '\\' / LineBreakSequence) . {
  return text()
}
/ '\\' escape:EscapeSequence {
  return escape
}
/ LineBreakSequence [\s]* {
  return ' '
}

// TODO: TemplateLiteral

// Escape handling code borrowed from official PEGjs example javascript.pegjs
// Some additional modifications applied

EscapeSequence
  = CharacterEscapeSequence
  / HexEscapeSequence
  / UnicodeEscapeSequence

CharacterEscapeSequence
  = SingleEscapeCharacter
  / NonEscapeCharacter

SingleEscapeCharacter
  = "'"
  / '"'
  / "\\"
  / "b"  { return "\b"; }
  / "f"  { return "\f"; }
  / "n"  { return "\n"; }
  / "r"  { return "\r"; }
  / "t"  { return "\t"; }
  / "v"  { return "\v"; }
  / "0"  { return "\0"; }

NonEscapeCharacter
  = !(EscapeCharacter / LineBreakSequence) . { return text(); }

EscapeCharacter
  = SingleEscapeCharacter
  / "x"
  / "u"

HexDigit
  = [0-9a-fA-F]

HexEscapeSequence
  = "x" digits:$(HexDigit HexDigit) {
      return String.fromCharCode(parseInt(digits, 16));
    }

UnicodeEscapeSequence
  = "u" digits:$(HexDigit HexDigit HexDigit HexDigit) {
      return String.fromCharCode(parseInt(digits, 16));
    }

ObjectLiteral
= '{' WL head:ObjectProperty tail:(WeakSep ObjectProperty)* WL '}' {
  return Node('ObjectExpression', {properties: list(head, tail)})
}

ObjectProperty
= key:PublicIdentifier PD '=' PD value:Expression {
  return Node('ObjectProperty', {
    key,
    value,
    computed: false,
    shorthand: false,
    decorators: []
  })
}
/ key:PublicIdentifier {
  return Node('ObjectProperty', {
    key,
    value: key,
    computed: false,
    shorthand: true,
    decorators: []
  })
}
/ key:PrivateIdentifier PD '=' PD value:Expression {
  return Node('ObjectProperty', {
    key: key.innerExpression,
    value,
    computed: true,
    shorthand: false,
    decorators: []
  })
}
/ key:PrivateIdentifier {
  return Node('ObjectProperty', {
    key: key.innerExpression,
    value: key,
    computed: true,
    shorthand: false,
    decorators: []
  })
}

ArrayLiteral
= '[' WL head:ListElement tail:(WeakSep ListElement)* WL ']' {
  return Node('ArrayExpression', {elements: list(head, tail)})
}

FunctionLiteral
= BasicFunctionClause
/ NamedFunctionClause
/ ShorthandFunctionClause

FunctionStatement
= node:NamedFunctionClause {
  node.type = 'FunctionDeclaration'
  return node
}

BasicFunctionClause
=K_fn params:FunctionParameter PD '=>' PD result:Expression {
  return Node('FunctionExpression', {
    id: null,
    params,
    generator: false,
    async: false,
    body: SubNode('BlockStatement', {
      body: [SubNode('ReturnStatement', {argument: result})],
      directives: []
    })
  })
}

NamedFunctionClause
= K_fn id:Identifier PD params:FunctionParameter PD '=>' PD result:Expression {
  return Node('FunctionExpression', {
    id,
    params,
    generator: false,
    async: false,
    body: SubNode('BlockStatement', {
      body: [SubNode('ReturnStatement', {argument: result})],
      directives: []
    })
  })
}

ShorthandFunctionClause
= '#' PD '(' WL result:Expression WL ')' {
  return Node('ArrowFunctionExpression', {
    params: [
      SubNode('Identifier', {name: 'private_0_'}),
      SubNode('Identifier', {name: 'private_1_'}),
      SubNode('Identifier', {name: 'private_2_'}),
      SubNode('Identifier', {name: 'private_3_'}),
      SubNode('Identifier', {name: 'private_4_'}),
      SubNode('Identifier', {name: 'private_5_'}),
    ],
    generator: false,
    async: false,
    body: result,
    expression: true
  })
}

FunctionParameter
= '(' WL head:AssignmentPattern tail:(WeakSep AssignmentPattern)* WL ')' {
  return list(head, tail)
}
/ pattern:AssignmentPattern {
  return [pattern]
}

Identifier
= PublicIdentifier
/ PrivateIdentifier
/ VoidIdentifier

PublicIdentifier
= !ReservedKeywords name:IdentifierName {
  return Node('Identifier', {name})
}

IdentifierName
= IdentifierStart (IdentifierPart &IdentifierPart)* IdentifierEnd {
  return text()
}
/ !'_' IdentifierStart {
  return text()
}

IdentifierStart
= UnicodeLetter
/ '$'
/ '_'

IdentifierPart
= IdentifierStart
/ UnicodeCombiningMark
/ UnicodeDigit
/ UnicodeConnectorPunctuation
/ '\u200C'
/ '\u200D'

IdentifierEnd
= !'_' IdentifierPart

UnicodeLetter
= Lu
/ Ll
/ Lt
/ Lm
/ Lo
/ Nl

UnicodeCombiningMark
= Mn
/ Mc

UnicodeDigit
= Nd

UnicodeConnectorPunctuation
= Pc

PrivateIdentifier
= SymbolIdentifier
/ NumberIdentifier
// ComputedIdentifier

SymbolIdentifier
= '#' id:$PublicIdentifier {
  return Node('Identifier', {
    name: `private_${id}_`,
    innerExpression: SubNode('Identifier', {
      name: `symbol_${id}_`
    })
  })
}

NumberIdentifier
= '#' id:$('0' / [1-9] [0-9]*) {
  return Node('Identifier', {
    name: `private_${id}_`,
    innerExpression: SubNode('NumericLiteral', {
      value: parseInt(id, 10)
    })
  })
}

VoidIdentifier
= K__ {
  return Node('Identifier', {name: '_'})
}

// TODO: ComputedIdentifier

ListElement
= SpreadElement
/ Expression

SpreadElement
= '...' PD argument:Expression {
  return Node('SpreadElement', {argument})
}

// Assignment/destructuring patterns

AssignmentPattern
= ObjectPattern
/ ArrayPattern
/ RestPattern
/ Identifier

ObjectPattern
= '{' WL head:PropertyPattern tail:(WeakSep PropertyPattern)* WL '}' {
  return Node('ObjectPattern', {properties: list(head, tail)})
}

PropertyPattern
= key:PublicIdentifier {
  return Node('ObjectProperty', {
    key,
    value: key,
    computed: false,
    shorthand: true,
    decorators: []
  })
}
/ key:PublicIdentifier PD K_as value:AssignmentPattern {
  return Node('ObjectProperty', {
    key,
    value,
    computed: false,
    shorthand: false,
    decorators: []
  })
}
/ key:PrivateIdentifier {
  return Node('ObjectProperty', {
    key: key.innerExpression,
    value: key,
    computed: true,
    shorthand: false,
    decorators: []
  })
}
/ key:PrivateIdentifier PD K_as value:AssignmentPattern {
  return Node('ObjectProperty', {
    key: key.innerExpression,
    value,
    computed: true,
    shorthand: false,
    decorators: []
  })
}

ArrayPattern
= '[' WL head:AssignmentPattern tail:(WeakSep AssignmentPattern)* WL ']' {
  return Node('ArrayPattern', {elements: list(head, tail)})
}

RestPattern
= '...' PD argument:Identifier {
  return Node('RestElement', {argument})
}

// Module

ImportClause
= K_import specifiers:ImportList PD 'from' PD source:StringLiteral {
  return Node('ImportDeclaration', {specifiers, source})
}
/ K_import 'from' PD source:StringLiteral {
  return Node('ImportDeclaration', {specifiers: [], source})
}

ImportList
= head:ImportElement tail:(WeakSep ImportElement)* {
  return list(head, tail)
    .reduce((acc, el) => Array.isArray(el) ? [...acc, ...el] : [...acc, el])
}

ImportElement
= ImportDefault
/ ImportNamespace
/ ImportVariables

ImportDefault
= local:PublicIdentifier {
  return Node('ImportDefaultSpecifier', {local})
}

ImportNamespace
= '*' PD K_as local:PublicIdentifier {
  return Node('ImportNamespaceSpecifier', {local})
}

ImportVariables
= '{' WL head:ImportSpecifier tail:(WeakSep ImportSpecifier)* WL '}' {
  return list(head, tail)
}

ImportSpecifier
= local:PublicIdentifier {
  return Node('ImportSpecifier', {imported: local, local})
}
/ imported:PublicIdentifier PD K_as local:PublicIdentifier {
  return Node('ImportSpecifier', {imported, local})
}

ExportClause
= K_export K_default declaration:Expression {
  return Node('ExportDefaultDeclaration', {declaration})
}
/ K_export declaration:(DeclarationStatement / FunctionStatement) {
  return Node('ExportNamedDeclaration', {
    declaration,
    source: null,
    specifiers: []
  })
}
/ K_export '{' WL head:ExportSpecifier tail:(WeakSep ExportSpecifier)* WL '}' PD 'from' PD source:StringLiteral {
  return Node('ExportNamedDeclaration', {
    declaration: null,
    source,
    specifiers: list(head, tail)
  })
}
/ K_export '{' WL head:ExportSpecifier tail:(WeakSep ExportSpecifier)* WL '}' {
  return Node('ExportNamedDeclaration', {
    declaration: null,
    source: null,
    specifiers: list(head, tail)
  })
}
/ K_export '*' PD 'from' PD source:StringLiteral {
  return Node('ExportAllDeclaration', {source})
}

// TODO: `export defaultMember from 'mylib'`
// TODO: `export * as namespace from 'mylib'`

ExportSpecifier
= local:PublicIdentifier {
  return Node('ExportSpecifier', {
    local,
    exported: local
  })
}
/ local:Identifier PD K_as exported:PublicIdentifier {
  return Node('ExportSpecifier', {local, exported})
}

// Common utilities

StatementList
= head:Statement tail:(StrongSep Statement)* {
  return list(head, tail)
}

StatementBlock
= '{' WL body:StatementList WL '}' {
  return Node('BlockStatement', {body, directives: []})
}

// Special lexical tokens

WhiteSpaceCharacter
= [\t\v\f \u00A0\uFEFF]
/ Zs

LineBreakSequence
= '\n'
/ '\r\n'
/ '\r'
/ '\u2028'
/ '\u2029'

LineEnd
= '//' (!LineBreakSequence .)* LineBreakSequence
/ LineBreakSequence

PD
= WhiteSpaceCharacter*

LB
= WhiteSpaceCharacter* LineEnd

WL
= WhiteSpaceCharacter* (LineEnd+ WhiteSpaceCharacter*)*

WeakSep
= PD ',' WL
/ LB WL

StrongSep
= PD ';' WL
/ LB WL
