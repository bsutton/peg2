import 'package:code_builder/code_builder.dart';
import 'package:code_builder/code_builder.dart' as _cb;

final false$ = literalFalse;

final null$ = literalNull;

final true$ = literalTrue;

Expression binaryExpression(Expression left, String operation, Expression rigth) {
  final code = <Code>[];
  code.add(left.code);
  code.add(Code(operation));
  code.add(rigth.code);  
  return codeToExpression(Block.of(code));
}

Expression callExpression(String name,
    [List<Expression> positionalArguments = const [],
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const []]) {
  return ref(name).call(positionalArguments, namedArguments, typeArguments);
}

Expression codeToExpression(Code code) {
  return CodeExpression(code);
}

Expression literal(Object literal) {
  if (literal is String) {
    return literalString(literal);
  }

  return _cb.literal(literal);
}

Expression literalList(Iterable values, [Reference? type]) {
  return _cb.literalList(values, type);
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

Expression methodCallExpression(Expression object, String property,
    [List<Expression> positionalArguments = const [],
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const []]) {
  return object
      .property(property)
      .call(positionalArguments, namedArguments, typeArguments);
}

Expression postfixExpression(Expression expression, String suffix) {
  final code = <Code>[];
  code.add(expression.code);
  code.add(Code(suffix));
  return codeToExpression(Block.of(code));
}

Reference ref(String symbol, [String? url]) => refer(symbol, url);

Code stringToCode(String code) {
  return Code(code);
}
