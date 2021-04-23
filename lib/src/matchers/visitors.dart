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

  T visitPostfixAndPredicate(PostfixAndPredicateMatcher node);

  T visitPostfixAnyCharacter(PostfixAnyCharacterMatcher node);

  T visitPostfixCapture(PostfixCaptureMatcher node);

  T visitPostfixCharacterClass(PostfixCharacterClassMatcher node);

  T visitPostfixLiteral(PostfixLiteralMatcher node);

  T visitPostfixNonterminal(PostfixNonterminalMatcher node);

  T visitPostfixNotPredicate(PostfixNotPredicateMatcher node);

  T visitPostfixOneOrMore(PostfixOneOrMoreMatcher node);

  T visitPostfixOptional(PostfixOptionalMatcher node);

  T visitPostfixOrderedChoice(PostfixOrderedChoiceMatcher node);

  T visitPostfixSequence(PostfixSequenceMatcher node);

  T visitPostfixSubterminal(PostfixSubterminalMatcher node);

  T visitPostfixTerminal(PostfixTerminalMatcher node);

  T visitPostfixZeroOrMore(PostfixZeroOrMoreMatcher node);

  T visitSequence(SequenceMatcher node);

  T visitSubterminal(SubterminalMatcher node);

  T visitTerminal(TerminalMatcher node);

  T visitZeroOrMore(ZeroOrMoreMatcher node);
}
