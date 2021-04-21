import 'package:code_builder/code_builder.dart';
import 'package:code_builder/code_builder.dart' as _cb;

Reference ref(String symbol, [String? url]) => refer(symbol, url);

final false$ = literalFalse;

final null$ = literalNull;

final true$ = literalTrue;

Expression callExpression(String name,
    [List<Expression> positionalArguments = const [],
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const []]) {
  return ref(name).call(positionalArguments, namedArguments, typeArguments);
}

Expression literalList(Iterable values, [Reference? type]) {
  return _cb.literalList(values, type);
}

Expression literal(Object literal) {
  if (literal is String) {
    return literalString(literal);
  }

  return _cb.literal(literal);
}

Expression methodCallExpression(Expression object, String property,
    [List<Expression> positionalArguments = const [],
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const []]) {
  return object
      .property(property)
      .call(positionalArguments, namedArguments, typeArguments);
}

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

Expression postfixExpression(Expression expression, String suffix) {
  final code = <Code>[];
  code.add(expression.code);
  code.add(Code(suffix));
  return codeToExpression(Block.of(code));
}

Expression codeToExpression(Code code) {
  return CodeExpression(code);
}
