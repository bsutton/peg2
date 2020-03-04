part of '../../postfix_parser_generator.dart';

class ExpressionChainResolver extends ExpressionVisitor {
  ExpressionNode _parent;

  List<Expression> _startExpressions;

  Set<Expression> _visited;

  ExpressionNode resolve(OrderedChoiceExpression expression) {
    _parent = ExpressionNode(null);
    _startExpressions = [];
    _visited = {};
    expression.accept(this);
    return _parent.children.first;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _processSingle(node);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _processChar(node);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _processSingle(node);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _processChar(node);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _processChar(node);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.expression.rule.expression.accept(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _processSingle(node);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _processSingle(node);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _processSingle(node);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (!_visited.add(node)) {
      //throw StateError('Recursive grammar');
    }

    final parent = _parent;
    final current = ExpressionNode(node);
    parent.addChild(current);
    for (final child in node.expressions) {
      _parent = current;
      child.accept(this);
    }

    _parent = parent;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final parent = _parent;
    final current = ExpressionNode(node);
    parent.addChild(current);
    _parent = current;
    final expressions = node.expressions;
    expressions[0].accept(this);
    /*
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      if (!child.isOptionalOrPredicate) {
        break;
      }
    }
    */

    _parent = parent;
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
    _processSingle(node);
  }

  void _processChar(Expression expression) {
    final current = ExpressionNode(expression);
    _parent.addChild(current);
    var prev = current;
    for (final expression in _startExpressions) {
      final node = ExpressionNode(expression);
      prev.addChild(node);
      prev = node;
    }

    _startExpressions.clear();
  }

  void _processSingle(SingleExpression expression) {
    final parent = _parent;
    final current = ExpressionNode(expression);
    parent.addChild(current);
    _parent = current;
    final start = StartExpression(expression);
    start.rule = expression.rule;
    _startExpressions.add(start);
    final child = expression.expression;
    child.accept(this);
    _parent = parent;
  }
}
