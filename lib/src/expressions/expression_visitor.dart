part of '../../expressions.dart';

abstract class ExpressionVisitor<T> {
  T visitAndPredicate(AndPredicateExpression node);

  T visitAnyCharacter(AnyCharacterExpression node);

  T visitCapture(CaptureExpression node);

  T visitCharacterClass(CharacterClassExpression node);

  T visitLiteral(LiteralExpression node);

  T visitNonterminal(NonterminalExpression node);

  T visitNotPredicate(NotPredicateExpression node);

  T visitOneOrMore(OneOrMoreExpression node);

  T visitOptional(OptionalExpression node);

  T visitOrderedChoice(OrderedChoiceExpression node);

  T visitSequence(SequenceExpression node);

  T visitSubterminal(SubterminalExpression node);

  T visitTerminal(TerminalExpression node);

  T visitZeroOrMore(ZeroOrMoreExpression node);
}
