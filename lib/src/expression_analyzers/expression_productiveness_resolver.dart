part of '../../expression_analyzers.dart';

class ExpressionProductivenessResolver extends ExpressionVisitor {
  bool _hasModifications;

  void resolve(Grammar grammar) {
    final start = grammar.start;
    final rules = grammar.rules;
    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        final expression = rule.expression;
        if (rule == start) {
          _setProductiveness(expression, Productiveness.always);
        } else {
          _setProductiveness(expression, Productiveness.auto);
        }

        expression.accept(this);
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
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
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final varCount = expressions.where((e) => e.variable != null).length;
    final hasAction = node.actionIndex != null;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (hasAction) {
        if (child.variable != null) {
          _setProductiveness(child, Productiveness.always);
        } else {
          _setProductiveness(child, Productiveness.never);
        }
      } else {
        if (i == 0 && varCount == 0) {
          _setProductiveness(child, Productiveness.auto);
        } else {
          if (child.variable != null) {
            _setProductiveness(child, Productiveness.auto);
          } else {
            _setProductiveness(child, Productiveness.never);
          }
        }
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    _setProductiveness(node.expression, node.productiveness);
    node.visitChildren(this);
  }

  void _setProductiveness(Expression node, Productiveness productiveness) {
    if (node.productiveness != productiveness) {
      node.productiveness = productiveness;
      _hasModifications = true;
    }
  }
}
