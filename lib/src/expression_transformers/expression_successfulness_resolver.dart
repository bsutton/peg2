part of '../../expression_transformers.dart';

class ExpressionSuccessfulnessResolver extends ExpressionVisitor {
  bool _hasModifications;

  void resolve(Grammar grammar) {
    final rules = grammar.rules;
    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        final expression = rule.expression;
        expression.accept(this);
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCapture(CaptureExpression node) {
    node.visitChildren(this);
    final child = node.expression;
    _setIsSuccessful(node, child.isSuccessful);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.visitChildren(this);
    final expression = node.expression;
    _setIsSuccessful(node, expression.isSuccessful);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    node.visitChildren(this);
    final child = node.expression;
    _setIsSuccessful(node, child.isSuccessful);
  }

  @override
  void visitOptional(OptionalExpression node) {
    node.visitChildren(this);
    _setIsSuccessful(node, true);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    node.visitChildren(this);
    final expressions = node.expressions;
    var count = 0;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (child.isSuccessful) {
        count++;
      }
    }

    if (count == expressions.length) {
      _setIsSuccessful(node, true);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    node.visitChildren(this);
    final expressions = node.expressions;
    var count = 0;
    var skip = false;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (!skip) {
        if (child.isSuccessful) {
          count++;
        } else {
          skip = true;
        }
      }
    }

    if (count == expressions.length) {
      _setIsSuccessful(node, true);
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    node.visitChildren(this);
    final expression = node.expression;
    _setIsSuccessful(node, expression.isSuccessful);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    node.visitChildren(this);
    final expression = node.expression;
    _setIsSuccessful(node, expression.isSuccessful);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    node.visitChildren(this);
    _setIsSuccessful(node, true);
  }

  void _setIsSuccessful(Expression node, bool isSuccessful) {
    if (!node.isSuccessful) {
      if (node.isSuccessful != isSuccessful) {
        node.isSuccessful = isSuccessful;
        _hasModifications = true;
      }
    }
  }
}
