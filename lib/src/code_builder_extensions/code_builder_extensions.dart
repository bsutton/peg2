// @dart = 2.10

import 'package:code_builder/code_builder.dart';

const Code break$ = Code('break;');

Code assign(String name, Expression expression) {
  return refer(name).assign(expression).statement;
}

Code assignConst(String name, Expression expression, [Reference type]) {
  return expression.assignConst(name, type).statement;
}

Code assignFinal(String name, Expression expression, [Reference type]) {
  return expression.assignFinal(name, type).statement;
}

Code assignVar(String name, Expression expression, [Reference type]) {
  return expression.assignVar(name, type).statement;
}

Expression call$(String name,
    [List<Expression> positionalArguments = const [],
    Map<String, Expression> namedArguments = const {}]) {
  return refer(name).call(positionalArguments, namedArguments);
}

Expression callMethod(String object, String name,
    [List<Expression> positionalArguments = const []]) {
  return property(object, name).call(positionalArguments);
}

Code declareVariable(Reference type, String name) {
  return Block.of(
      [type.code, const Code(' '), refer(name).code, const Code(';')]);
}

Code else$(void Function(List<Code> code) block) {
  final code = <Code>[];
  block(code);
  return CodeExpression(Block.of([
    const Code('else {'),
    lazyCode(() => Block.of(code)),
    const Code('}'),
  ])).code;
}

Code elseIf$(Expression expression, void Function(List<Code> code) block) =>
    _statement('else if', expression, block);

Code for$(Reference type, Reference identifier, Expression expression,
        void Function(List<Code> code) block) =>
    _statement(
        'for',
        CodeExpression(Block.of([
          type.code,
          const Code(' '),
          identifier.code,
          const Code(' in '),
          expression.code
        ])),
        block);

Code if$(Expression expression, void Function(List<Code> code) block) =>
    _statement('if', expression, block);

Expression literalString(String value) {
  value = value.replaceAll('\\', r'\\');
  value = value.replaceAll('\b', r'\b');
  value = value.replaceAll('\f', r'\f');
  value = value.replaceAll('\n', r'\n');
  value = value.replaceAll('\r', r'\r');
  value = value.replaceAll('\t', r'\t');
  value = value.replaceAll('\v', r'\v');
  value = value.replaceAll('\'', '\\\'');
  value = value.replaceAll('\$', r'\$');
  value = '\'$value\'';
  return CodeExpression(Code(value));
}

Expression nullCheck(Expression expression) {
  return CodeExpression(Block.of([expression.code, const Code('!')]));
}

Expression property(String object, String name) {
  return refer(object).property(name);
}

Code switch$(Expression expression, Map<List<Expression>, List<Code>> cases,
    [List<Code> default_]) {
  final code = <Code>[];
  for (final entry in cases.entries) {
    for (final case_ in entry.key) {
      code.addAll([
        const Code('case '),
        case_.code,
        const Code(':'),
      ]);
    }

    code.addAll(entry.value);
  }

  if (default_ != null) {
    code.addAll([const Code('default:\n'), ...default_]);
  }

  return _statement('switch', expression, (_) => code);
}

Code while$(Expression expression, void Function(List<Code> code) block) =>
    _statement('while', expression, block);

Code _statement(
    String name, Expression expression, void Function(List<Code> code) block) {
  final code = <Code>[];
  block(code);
  return CodeExpression(Block.of([
    Code(name),
    const Code(' ('),
    expression.code,
    const Code(') {'),
    lazyCode(() => Block.of(code)),
    const Code('}'),
  ])).code;
}

class IfElseGenerator {
  final Expression expression;

  final List<Code> _elseCode = [];

  final List<Code> _ifCode = [];

  IfElseGenerator(this.expression);

  void elseCode(void Function(List<Code>) block) {
    block(_elseCode);
  }

  List<Code> generate() {
    final code = <Code>[];
    if (_ifCode.isNotEmpty) {
      code <<
          if$(expression, (code) {
            code.addAll(_ifCode);
          });

      if (_elseCode.isNotEmpty) {
        code <<
            else$((code) {
              code.addAll(_elseCode);
            });
      }
    } else if (_elseCode.isNotEmpty) {
      code <<
          if$(expression.negate(), (code) {
            code.addAll(_elseCode);
          });
    }

    return code;
  }

  void ifCode(void Function(List<Code>) block) {
    block(_ifCode);
  }
}

extension CodeListExtension on List<Code> {
  List<Code> operator <<(Code code) {
    add(code);
    return this;
  }
}

extension ExpressionExtension on Expression {
  Expression asWithoutParenthesis(Expression type) => CodeExpression(Block.of([
        code,
        const Code(' as '),
        type.code,
      ]));

  Expression preOp(String op) => CodeExpression(Block.of([Code(op), code]));

  Expression postOp(String op) => CodeExpression(Block.of([code, Code(op)]));
}
