part of '../../experimental.dart';

class ExpressionChainResolver extends ExpressionVisitor {
  _Node _node;

  Set<Expression> _visited;

  _Node resolve(ProductionRule rule) {
    _node = _Node(null);
    _visited = {};
    rule.expression.accept(this);
    return _node.children.first;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _node.addChild(_Node(node));
  }

  @override
  void visitCapture(CaptureExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _node.addChild(_Node(node));
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _node.addChild(_Node(node));
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.expression.rule.expression.accept(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitOptional(OptionalExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (!_visited.add(node)) {
      //throw StateError('Recursive grammar');
    }

    final prevNode = _node;
    _node = _Node(node);
    for (final child in node.expressions) {
      child.accept(this);
    }

    prevNode.addChild(_node);
    _node = prevNode;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final prevNode = _node;
    _node = _Node(node);
    //node.expressions[0].accept(this);
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

    prevNode.addChild(_node);
    _node = prevNode;
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
    node.expression.accept(this);
  }
}

class _Node {
  final Expression expression;

  List<_Node> children = [];

  _Node(this.expression);

  void addChild(_Node child) {
    children.add(child);
  }
}
