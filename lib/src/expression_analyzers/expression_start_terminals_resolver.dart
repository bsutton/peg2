part of '../../expression_analyzers.dart';

class ExpressionStartTerminalsResolver extends SimpleExpressionVisitor {
  bool _hasModifications;

  void resolve(List<ProductionRule> rules) {
    if (rules == null) {
      throw ArgumentError.notNull('rules');
    }

    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        rule.expression.accept(this);
      }
    }
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    child.accept(this);
    _addTerminals(node, child.startTerminals);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _addTerminals(node, child.startTerminals);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
      _addTerminals(node, child.startTerminals);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    var skip = false;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
      if (!skip && !child.isOptional) {
        _addTerminals(node, child.startTerminals);
      }

      if (!child.isOptional) {
        skip = true;
      }
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final child = node.expression;
    _addTerminals(node, child.startTerminals);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final child = node.expression;
    final rule = child.rule;
    _addTerminals(node, [rule]);
  }

  void _addTerminals(Expression node, Iterable<ProductionRule> terminals) {
    final startTerminals = node.startTerminals;
    for (final terminal in terminals) {
      if (startTerminals.add(terminal)) {
        _hasModifications = true;
      }
    }
  }
}
