part of '../../expression_analyzers.dart';

class ExpressionInitializer1 {
  void initialize(Grammar grammar) {
    final rules = grammar.rules;
    final optionalExpressionResolver = OptionalExpressionResolver();
    optionalExpressionResolver.resolve(rules);

    final expressionProductivenessResolver = ExpressionProductivenessResolver();
    expressionProductivenessResolver.resolve(grammar);

    final expressionStartCharactersResolver =
        ExpressionStartCharactersResolver();
    expressionStartCharactersResolver.resolve(rules);

    final expressionStartTerminalsResolver = ExpressionStartTerminalsResolver();
    expressionStartTerminalsResolver.resolve(rules);

    final expressionSuccessfulnessResolver = ExpressionSuccessfulnessResolver();
    expressionSuccessfulnessResolver.resolve(grammar);

    final expressionReturnTypeResolver = ExpressionReturnTypeResolver();
    expressionReturnTypeResolver.resolve(rules);
  }
}
