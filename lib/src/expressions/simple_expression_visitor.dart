part of '../../expressions.dart';

class SimpleExpressionVisitor<T> extends ExpressionVisitor<T?> {
  T? visit(Expression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  T? visitAndPredicate(AndPredicateExpression node) => visit(node);

  @override
  T? visitAnyCharacter(AnyCharacterExpression node) => visit(node);

  @override
  T? visitCapture(CaptureExpression node) => visit(node);

  @override
  T? visitCharacterClass(CharacterClassExpression node) => visit(node);

  @override
  T? visitLiteral(LiteralExpression node) => visit(node);

  @override
  T? visitNonterminal(NonterminalExpression node) => visit(node);

  @override
  T? visitNotPredicate(NotPredicateExpression node) => visit(node);

  @override
  T? visitOneOrMore(OneOrMoreExpression node) => visit(node);

  @override
  T? visitOptional(OptionalExpression node) => visit(node);

  @override
  T? visitOrderedChoice(OrderedChoiceExpression node) => visit(node);

  @override
  T? visitSequence(SequenceExpression node) => visit(node);

  @override
  T? visitSubterminal(SubterminalExpression node) => visit(node);

  @override
  T? visitTerminal(TerminalExpression node) => visit(node);

  @override
  T? visitZeroOrMore(ZeroOrMoreExpression node) => visit(node);
}
