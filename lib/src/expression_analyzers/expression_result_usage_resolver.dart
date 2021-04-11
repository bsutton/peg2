part of '../../expression_analyzers.dart';

class ExpressionResultUsageResolver extends ExpressionVisitor<void> {
  var _hasModifications = false;

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
    _visitSingle(node, false);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    //
  }

  @override
  void visitCapture(CaptureExpression node) {
    _visitSingle(node, false);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    //
  }

  @override
  void visitLiteral(LiteralExpression node) {
    //
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _visitSingle(node, false);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _visitSingle(node, node.resultUsed);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _visitSingle(node, node.resultUsed);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final resultUsed = node.resultUsed;
    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      _setResultUsed(child, resultUsed);
      child.accept(this);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final resultUsed = node.resultUsed;
    final hasAction = node.actionIndex != null;
    final expressions = node.expressions;
    final hasVariables =
        expressions.where((e) => e.variable != null).isNotEmpty;
    if (resultUsed && !hasVariables && !hasAction) {
      final first = expressions.first;
      _setResultUsed(first, true);
    }

    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (child.variable != null) {
        if (resultUsed || hasAction) {
          _setResultUsed(child, true);
        }
      }

      child.accept(this);
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    _visitSingle(node, node.resultUsed);
  }

  void _acceptChild(Expression child, bool resultUsed) {
    if (resultUsed) {
      _setResultUsed(child, true);
    }

    child.accept(this);
  }

  void _setResultUsed(Expression node, bool resultUsed) {
    if (node.resultUsed != resultUsed) {
      _hasModifications = true;
      node.resultUsed = resultUsed;
    }
  }

  void _visitSingle(SingleExpression node, bool resultUsed) {
    final child = node.expression;
    _acceptChild(child, resultUsed);
  }

  void _visitSymbol(SymbolExpression node) {
    final resultUsed = node.resultUsed;
    if (resultUsed) {
      final expression = node.expression!;
      _setResultUsed(expression, true);
    }
  }
}
