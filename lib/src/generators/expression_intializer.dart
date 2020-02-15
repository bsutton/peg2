part of '../../generators.dart';

class ExpressionInitializer extends ExpressionVisitor<Object> {
  int _actionIndex;

  int _expressionId;

  int _level;

  ProductionRule _rule;

  Map<String, ProductionRule> _rules;

  void initialize(List<ProductionRule> rules) {
    if (rules == null) {
      throw ArgumentError.notNull('rules');
    }

    _rules = <String, ProductionRule>{};
    for (var rule in rules) {
      _rules[rule.name] = rule;
    }

    _actionIndex = 0;
    _expressionId = 0;
    for (var rule in rules) {
      _level = 0;
      _rule = rule;
      rule.expression.accept(this);
    }
  }

  @override
  Object visitAndPredicate(AndPredicateExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitAnyCharacter(AnyCharacterExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitCapture(CaptureExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitCharacterClass(CharacterClassExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitLiteral(LiteralExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitNonterminal(NonterminalExpression node) {
    _initializeNode(node);
    final rule = _rules[node.name];
    if (rule == null) {
      throw StateError('Production rule not found: ${node.name}');
    }

    node.expression = rule.expression;
    return null;
  }

  @override
  Object visitNotPredicate(NotPredicateExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitOneOrMore(OneOrMoreExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitOptional(OptionalExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitOrderedChoice(OrderedChoiceExpression node) {
    _initializeNode(node);
    return null;
  }

  @override
  Object visitSequence(SequenceExpression node) {
    _initializeNode(node);
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.index = i;
    }

    if (node.actionSource != null) {
      node.actionIndex = _actionIndex++;
    }

    return null;
  }

  @override
  Object visitSubterminal(SubterminalExpression node) {
    _initializeNode(node);
    final rule = _rules[node.name];
    if (rule == null) {
      throw StateError('Production rule not found: ${node.name}');
    }

    node.expression = rule.expression;
    return null;
  }

  @override
  Object visitTerminal(TerminalExpression node) {
    _initializeNode(node);
    final rule = _rules[node.name];
    if (rule == null) {
      throw StateError('Production rule not found: ${node.name}');
    }

    node.expression = rule.expression;
    return null;
  }

  @override
  Object visitZeroOrMore(ZeroOrMoreExpression node) {
    _initializeNode(node);
    return null;
  }

  void _initializeNode(Expression node) {
    if (node is SingleExpression) {
      final child = node.expression;
      child.isLast = true;
    } else if (node is MultipleExpression) {
      final last = node.expressions.last;
      last.isLast = true;
    }

    node.index = 0;
    node.rule = _rule;
    node.id = _expressionId++;
    node.level = _level;
    final level = _level;
    _level++;
    node.visitChildren(this);
    _level = level;
  }
}
