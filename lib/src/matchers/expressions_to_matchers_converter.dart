part of '../../matchers.dart';

class ExpressionsToMatchersConverter extends ExpressionVisitor<Matcher> {
  @override
  Matcher visitAndPredicate(AndPredicateExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return AndPredicateMatcher(node, matcher);
  }

  @override
  Matcher visitAnyCharacter(AnyCharacterExpression node) {
    return AnyCharacterMatcher(node);
  }

  @override
  Matcher visitCapture(CaptureExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return CaptureMatcher(node, matcher);
  }

  @override
  Matcher visitCharacterClass(CharacterClassExpression node) {
    return CharacterClassMatcher(node);
  }

  @override
  Matcher visitLiteral(LiteralExpression node) {
    return LiteralMatcher(node);
  }

  @override
  Matcher visitNonterminal(NonterminalExpression node) {
    return NonterminalMatcher(node);
  }

  @override
  Matcher visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return NotPredicateMatcher(node, matcher);
  }

  @override
  Matcher visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return OneOrMoreMatcher(node, matcher);
  }

  @override
  Matcher visitOptional(OptionalExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return OptionalMatcher(node, matcher);
  }

  @override
  Matcher visitOrderedChoice(OrderedChoiceExpression node) {
    final matchers = _visitMultiple(node);
    return OrderedChoiceMatcher(node, matchers);
  }

  @override
  Matcher visitSequence(SequenceExpression node) {
    final matchers = _visitMultiple(node);
    return SequenceMatcher(node, matchers);
  }

  @override
  Matcher visitSubterminal(SubterminalExpression node) {
    return SubterminalMatcher(node);
  }

  @override
  Matcher visitTerminal(TerminalExpression node) {
    return TerminalMatcher(node);
  }

  @override
  Matcher visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    final matcher = child.accept(this);
    return ZeroOrMoreMatcher(node, matcher);
  }

  List<Matcher> _visitMultiple(MultipleExpression expression) {
    final matchers = <Matcher>[];
    final expressions = expression.expressions;
    for (final child in expressions) {
      final matcher = child.accept(this);
      matchers.add(matcher);
    }

    return matchers;
  }
}
