part of '../../generators.dart';

class ExpressionTransformationInitializer extends ExpressionVisitor<Object> {
  bool _hasModifications;

  void initialize(List<ProductionRule> rules) {
    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        rule.expression.accept(this);
      }
    }
  }

  @override
  Object visitAndPredicate(AndPredicateExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitAnyCharacter(AnyCharacterExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitCapture(CaptureExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitCharacterClass(CharacterClassExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitLiteral(LiteralExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitNonterminal(NonterminalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitNotPredicate(NotPredicateExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitOneOrMore(OneOrMoreExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitOptional(OptionalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitOrderedChoice(OrderedChoiceExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitSequence(SequenceExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitSubterminal(SubterminalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitTerminal(TerminalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitZeroOrMore(ZeroOrMoreExpression node) {
    node.visitChildren(this);
    return null;
  }
}
