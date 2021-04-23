part of '../../matcher_generators.dart';

class MatcherGeneratorBase extends MatcherVisitor<MatcherGenerator> {
  BitFlagGenerator failures;

  MatcherGeneratorBase({required this.failures});

  @override
  MatcherGenerator visitAndPredicate(AndPredicateMatcher node) {
    return AndPredicateGenerator(node, failures);
  }

  @override
  MatcherGenerator visitAnyCharacter(AnyCharacterMatcher node) {
    return AnyCharacterGenerator(node);
  }

  @override
  MatcherGenerator visitCapture(CaptureMatcher node) {
    return CaptureGenerator(node);
  }

  @override
  MatcherGenerator visitCharacterClass(CharacterClassMatcher node) {
    return CharacterClassGenerator(node);
  }

  @override
  MatcherGenerator visitLiteral(LiteralMatcher node) {
    return LiteralGenerator(node);
  }

  @override
  MatcherGenerator<Matcher<Expression>> visitNonterminal(
      NonterminalMatcher node) {
    return NonterminalGenerator(node);
  }

  @override
  MatcherGenerator visitNotPredicate(NotPredicateMatcher node) {
    return NotPredicateGenerator(node, failures);
  }

  @override
  MatcherGenerator visitOneOrMore(OneOrMoreMatcher node) {
    return OneOrMoreGenerator(node);
  }

  @override
  MatcherGenerator visitOptional(OptionalMatcher node) {
    return OptionalGenerator(node);
  }

  @override
  MatcherGenerator visitOrderedChoice(OrderedChoiceMatcher node) {
    return OrderedChoiceGenerator(node, failures);
  }

  @override
  MatcherGenerator visitPostfixAndPredicate(PostfixAndPredicateMatcher node) {
    return PostfixAndPredicateGenerator(node, failures);
  }

  @override
  MatcherGenerator visitPostfixAnyCharacter(PostfixAnyCharacterMatcher node) {
    return PostfixAnyCharacterGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixCapture(PostfixCaptureMatcher node) {
    return PostfixCaptureGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixCharacterClass(
      PostfixCharacterClassMatcher node) {
    return PostfixCharacterClassGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixLiteral(PostfixLiteralMatcher node) {
    return PostfixLiteralGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixNonterminal(PostfixNonterminalMatcher node) {
    return PostfixNonterminalGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixNotPredicate(PostfixNotPredicateMatcher node) {
    return PostfixNotPredicateGenerator(node, failures);
  }

  @override
  MatcherGenerator visitPostfixOneOrMore(PostfixOneOrMoreMatcher node) {
    return PostfixOneOrMoreGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixOptional(PostfixOptionalMatcher node) {
    return PostfixOptionalGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixOrderedChoice(PostfixOrderedChoiceMatcher node) {
    return PostfixOrderedChoiceGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixSequence(PostfixSequenceMatcher node) {
    return PostfixSequenceGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixSubterminal(PostfixSubterminalMatcher node) {
    return PostfixSubterminalGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixTerminal(PostfixTerminalMatcher node) {
    return PostfixTerminalGenerator(node);
  }

  @override
  MatcherGenerator visitPostfixZeroOrMore(PostfixZeroOrMoreMatcher node) {
    return PostfixZeroOrMoreGenerator(node);
  }

  @override
  MatcherGenerator visitSequence(SequenceMatcher node) {
    return SequenceGenerator(node);
  }

  @override
  MatcherGenerator<Matcher<Expression>> visitSubterminal(
      SubterminalMatcher node) {
    return SubterminalGenerator(node);
  }

  @override
  MatcherGenerator<Matcher<Expression>> visitTerminal(TerminalMatcher node) {
    return TerminalGenerator(node);
  }

  @override
  MatcherGenerator visitZeroOrMore(ZeroOrMoreMatcher node) {
    return ZeroOrMoreGenerator(node);
  }
}
