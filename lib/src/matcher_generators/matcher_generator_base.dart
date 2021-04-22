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
