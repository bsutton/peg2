part of '../../expressions.dart';

abstract class ExpressionVisitor {
  void visitAndPredicate(AndPredicateExpression node);

  void visitAnyCharacter(AnyCharacterExpression node);

  void visitCapture(CaptureExpression node);

  void visitCharacterClass(CharacterClassExpression node);

  void visitLiteral(LiteralExpression node);

  void visitNonterminal(NonterminalExpression node);

  void visitNotPredicate(NotPredicateExpression node);

  void visitOneOrMore(OneOrMoreExpression node);

  void visitOptional(OptionalExpression node);

  void visitOrderedChoice(OrderedChoiceExpression node);

  void visitSequence(SequenceExpression node);

  void visitSubterminal(SubterminalExpression node);

  void visitTerminal(TerminalExpression node);

  void visitZeroOrMore(ZeroOrMoreExpression node);
}
