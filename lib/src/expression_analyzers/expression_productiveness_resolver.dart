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
          _setIsProductive(expression, true);
        }

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
    final expression = node.expression;
    _setIsProductive(expression, node.isProductive);
    node.visitChildren(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    _setIsProductive(child, node.isProductive);
    node.visitChildren(this);
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    _setIsProductive(child, node.isProductive);
    node.visitChildren(this);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      _setIsProductive(child, node.isProductive);
    }

    node.visitChildren(this);
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final varCount = expressions.where((e) => e.variable != null).length;
    final hasAction = node.actionIndex != null;
    final isProductive = node.isProductive;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (hasAction) {
        if (i == 0 && varCount == 0) {
          child.isProductive = true;
        } else {
          if (child.variable != null) {
            child.isProductive = true;
          }
        }
      } else {
        if (i == 0 && varCount == 0) {
          _setIsProductive(child, isProductive);
        } else {
          if (child.variable != null) {
            _setIsProductive(child, isProductive);
          }
        }
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final expression = node.expression;
    _setIsProductive(expression, node.isProductive);
    node.visitChildren(this);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final expression = node.expression;
    _setIsProductive(expression, node.isProductive);
    node.visitChildren(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final expression = node.expression;
    _setIsProductive(expression, node.isProductive);
    node.visitChildren(this);
  }

  void _setIsProductive(Expression node, bool isProductive) {
    if (!node.isProductive) {
      if (node.isProductive != isProductive) {
        node.isProductive = isProductive;
        _hasModifications = true;
      }
    }
  }
}
