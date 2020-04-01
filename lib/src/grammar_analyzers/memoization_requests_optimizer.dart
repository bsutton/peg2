part of '../../grammar_analyzers.dart';

class MemoizationRequestsOptimizer extends SimpleExpressionVisitor {
  bool _hasModifications;

  void optimize(List<ProductionRule> rules) {
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
  void visitNonterminal(NonterminalExpression node) {
    super.visitNonterminal(node);
    _visitSymbol(node);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    super.visitSubterminal(node);
    _visitSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    super.visitTerminal(node);
    _visitSymbol(node);
  }

  void _setMemoize(SymbolExpression node, bool memoize) {
    if (node.memoize != memoize) {
      node.memoize = memoize;
      _hasModifications = true;
    }
  }

  void _visitSymbol(SymbolExpression node) {
    if (node.memoize) {
      final owner = node.rule;
      final rule = node.expression.rule;
      final memoizationRequests = owner.memoizationRequests;
      if (memoizationRequests.isNotEmpty && owner != rule) {
        _setMemoize(node, false);
        rule.memoizationRequests.remove(node);
      }
    }
  }
}
