part of '../../expression_transformers.dart';

class OptionalExpressionResolver extends ExpressionVisitor {
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
  void visitAndPredicate(AndPredicateExpression node) {
    _setIsOptional(node, false, true);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _setIsOptional(node, false, false);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _setIsOptional(node, false, false);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _setIsOptional(node, false, false);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _setIsOptional(node, false, false);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final child = node.expression;
    _setIsOptional(node, child.isOptional, child.isOptionalOrPredicate);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _setIsOptional(node, false, true);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, child.isOptional, child.isOptionalOrPredicate);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _setIsOptional(node, true, false);
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
    final isOptionalOrPredicate =
        expressions.where((e) => e.isOptionalOrPredicate).length == length;
    _setIsOptional(node, isOptional, isOptionalOrPredicate);
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
    final isOptionalOrPredicate =
        expressions.where((e) => e.isOptionalOrPredicate).length == length;
    _setIsOptional(node, isOptional, isOptionalOrPredicate);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final child = node.expression;
    _setIsOptional(node, child.isOptional, child.isOptionalOrPredicate);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final child = node.expression;
    _setIsOptional(node, child.isOptional, child.isOptionalOrPredicate);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _setIsOptional(node, true, child.isOptionalOrPredicate);
  }

  void _setIsOptional(Expression node, bool isOptional, bool isPredicate) {
    if (node.isOptional != isOptional) {
      _hasModifications = true;
      node.isOptional = isOptional;
    }

    if (node.isPredicate != isPredicate) {
      _hasModifications = true;
      node.isPredicate = isPredicate;
    }

    if (node.isOptionalOrPredicate != isPredicate) {
      _hasModifications = true;
      node.isOptionalOrPredicate = isPredicate;
    }
  }
}
