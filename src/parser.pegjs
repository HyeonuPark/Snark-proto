{
  function Node (type, data) {
    const {start, end} = location()

    return Object.assign({}, {
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
= importBlock:ImportBlock statementBlock:RootLevelStatementBlock {
  return Node('Program'{
    sourceType: 'module',
    body: [...importBlock, ...statementBlock],
    directives: [],
  })
}

ImportBlock
= WL head:ImportClause tail:(StrongSep ImportClause)* WL {
  return list(head, tail)
}
/ WL {
  return []
}

RootLevelStatementBlock
= WL head:RootLevelStatement tail:(StrongSep RootLevelStatement)* WL {
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
= K_for isAsync:K_await? id:AssignmentPattern right:Expression body:StatementBlock {
  body.body.unshift(SubNode('VariableDeclaration', {
    kind: 'const',
    declarations: [SubNode('VariableDeclarator', {
      id,
      init: SubNode('Identifier', {name: 'iter_each__'})
    })]
  }))

  return Node('ForOfStatement', {
    left: SubNode('VariableDeclaration', {
      kind: 'let',
      declarations: [SubNode('VariableDeclarator', {
        id: SubNode('Identifier', {name: 'iter_each__'})
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
= K_not argument:ArithmeticExpression {
  return Node('UnaryExpression', {
    operator: '!',
    prefix: true,
    argument
  })
}
/ ArithmeticExpression

// TODO: PatternInExpression

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
=

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
=

ObjectPropertyClause
=

VirtualMethodClause
=

CollectionSetterClause
=

CollectionGetterClause
=

LiteralExpression
= KeywordLiteral
/ SwitchLiteral
/ DoLiteral
/ NumberLiteral
/ StringLiteral
/ TemplateStringLiteral
/ ObjectLiteral
/ ArrayLiteral
/ RangeLiteral
/ Identifier
/ '(' WL expr:Expression WL ')' {
  return expr
}

KeywordLiteral
=

SwitchLiteral
=

DoLiteral
=

NumberLiteral
=

StringLiteral
=

TemplateStringLiteral
=

ObjectLiteral
=

ArrayLiteral
=

RangeLiteral
=

Identifier
=

// Assignment patterns

AssignmentPattern
= ObjectPattern
/ ArrayPattern
/ IdentifierPattern

ObjectPattern
=

ArrayPattern
=

IdentifierPattern
=

// Module

ImportClause
=

ExportClause
=

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

WS
= WhiteSpaceCharacter+

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
