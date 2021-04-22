part of '../../matchers.dart';

abstract class MatcherVisitor<T> {
  T visitAndPredicate(AndPredicateMatcher node);

  T visitAnyCharacter(AnyCharacterMatcher node);

  T visitCapture(CaptureMatcher node);

  T visitCharacterClass(CharacterClassMatcher node);

  T visitLiteral(LiteralMatcher node);

  T visitNonterminal(NonterminalMatcher node);

  T visitNotPredicate(NotPredicateMatcher node);

  T visitOneOrMore(OneOrMoreMatcher node);

  T visitOptional(OptionalMatcher node);

  T visitOrderedChoice(OrderedChoiceMatcher node);

  T visitSequence(SequenceMatcher node);

  T visitSubterminal(SubterminalMatcher node);

  T visitTerminal(TerminalMatcher node);

  T visitZeroOrMore(ZeroOrMoreMatcher node);
}
