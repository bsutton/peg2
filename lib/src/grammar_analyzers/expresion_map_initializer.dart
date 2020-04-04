part of '../../grammar_analyzers.dart';

class ExpresionMapInitializer extends SimpleExpressionVisitor {
  Map<int, Expression> _expressionMap;

  void initialize(Grammar grammar) {
    _expressionMap = {};
    for (final rule in grammar.rules) {
      final expression = rule.expression;
      expression.accept(this);
    }

    grammar.expressionMap = _expressionMap;
  }

  @override
  void visit(Expression node) {
    _expressionMap[node.id] = node;
    node.visitChildren(this);
  }
}
