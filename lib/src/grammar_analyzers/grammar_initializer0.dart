part of '../../grammar_analyzers.dart';

class GrammarInitializer0 {
  void initialize(Grammar grammar, List<String> errors, List<String> warnings) {
    final expressionInitializer0 = ExpressionInitializer0();
    expressionInitializer0.initialize(grammar);
    final invocationsResolver = InvocationsResolver();
    invocationsResolver.resolve(grammar);
    final startingRulesFinder = StartingRulesFinder();
    final startingRules = startingRulesFinder.find(grammar);
    if (startingRules.isEmpty) {
      grammar.start = grammar.rules.first;
    } else if (startingRules.length > 1) {
      final names = startingRules.map((e) => e.name);
      errors.add('Found several starting rules: ${names.join(', ')}');
    } else {
      grammar.start = startingRules.first;
    }

    final expresionMapInitializer = ExpresionMapInitializer();
    expresionMapInitializer.initialize(grammar);
  }
}
