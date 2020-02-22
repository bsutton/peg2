part of '../../experimental.dart';

class ExpressionChainResolver extends ExpressionVisitor {
  ExpressionNode _node;

  Set<Expression> _visited;

  ExpressionNode resolve(OrderedChoiceExpression expression) {
    _node = ExpressionNode(null);
    _visited = {};
    expression.accept(this);
    return _node.children.first;
  }

  ExpressionNode _newNode(Expression expression) {
    final prev = _node;
    _node = ExpressionNode(expression);
    return prev;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _node.addChild(ExpressionNode(node));
  }

  @override
  void visitCapture(CaptureExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _node.addChild(ExpressionNode(node));
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _node.addChild(ExpressionNode(node));
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.expression.rule.expression.accept(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (!_visited.add(node)) {
      //throw StateError('Recursive grammar');
    }

    final prev = _newNode(node);
    for (final child in node.expressions) {
      child.accept(this);
    }

    prev.addChild(_node);
    _node = prev;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final prev = _newNode(node);
    node.expressions[0].accept(this);
    /*
    for (final child in node.expressions) {
      child.accept(this);
      if (child is AndPredicateExpression ||
          child is NotPredicateExpression ||
          child is OptionalExpression ||
          child is ZeroOrMoreExpression) {
        //
      } else {
        break;
      }
    }
    */

    prev.addChild(_node);
    _node = prev;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    node.expression.rule.expression.accept(this);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    node.expression.rule.expression.accept(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final prev = _newNode(node);
    node.expression.accept(this);
    _node = prev;
  }
}
