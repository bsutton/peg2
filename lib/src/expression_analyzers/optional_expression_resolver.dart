part of '../../expression_analyzers.dart';

class OptionalExpressionResolver extends ExpressionVisitor<void> {
  bool _hasModifications = false;

  void resolve(List<ProductionRule> rules) {
    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        rule.expression.accept(this);
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, false);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _setIsOptional(node, false);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, child.isOptional);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _setIsOptional(node, false);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _setIsOptional(node, false);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final child = node.expression!;
    _setIsOptional(node, child.isOptional);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, false);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, child.isOptional);
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, true);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
    }

    final isOptional = expressions.where((e) => e.isOptional).length == length;
    _setIsOptional(node, isOptional);
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
    }

    final isOptional = expressions.where((e) => e.isOptional).length == length;
    _setIsOptional(node, isOptional);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final child = node.expression!;
    _setIsOptional(node, child.isOptional);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final child = node.expression!;
    _setIsOptional(node, child.isOptional);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, true);
  }

  void _setIsOptional(Expression node, bool isOptional) {
    if (isOptional) {
      if (node.isOptional != isOptional) {
        _hasModifications = true;
        node.isOptional = isOptional;
      }
    }
  }
}
