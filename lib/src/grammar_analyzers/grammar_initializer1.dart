part of '../../grammar_analyzers.dart';

class GrammarInitializer1 {
  void initialize(Grammar grammar, List<String> errors, List<String> warnings) {
    final expressionInitializer1 = ExpressionInitializer1();
    expressionInitializer1.initialize(grammar);
  }
}
