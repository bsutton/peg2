part of '../../analyzers.dart';

class GrammarAnalyzer {
  List<String> _errors;

  List<String> analyze(Grammar grammar) {
    if (grammar == null) {
      throw ArgumentError.notNull('grammar');
    }

    _errors = <String>[];
    //final rules = grammar.rules;
    // Analyze
    return _errors;
  }

  /*
  void _addError(Expression expression, String message) {
    final rule = expression.rule;
    final sb = StringBuffer();
    sb.write('Rule ');
    sb.write(rule);
    sb.write(': ');
    sb.write(message);
  }
  */
}
