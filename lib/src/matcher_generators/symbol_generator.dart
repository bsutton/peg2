part of '../../matcher_generators.dart';

class SymbolGenerator<E extends SymbolMatcher> extends MatcherGenerator<E> {
  SymbolGenerator(E matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    allocateVariable();
    final expression = matcher.expression;
    final rule = expression.expression!.rule!;
    final nameGenerator = ProductionRuleNameGenerator();
    final identifier = nameGenerator.generate(rule);
    final call = callExpression(identifier);
    if (isVariableDeclared) {
      block.assign(variable!, call);
    } else {
      block.callAndTryAssignFinal(variable, call);
    }
  }
}
