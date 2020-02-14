part of '../../expressions.dart';

class SimpleExpressionVisitor<T> extends ExpressionVisitor {
  T visit(Expression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAndPredicate(AndPredicateExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitAnyCharacter(AnyCharacterExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitCapture(CaptureExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitCharacterClass(CharacterClassExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitLiteral(LiteralExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitNonterminal(NonterminalExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitNotPredicate(NotPredicateExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitOneOrMore(OneOrMoreExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitOptional(OptionalExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitOrderedChoice(OrderedChoiceExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitSequence(SequenceExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitSubterminal(SubterminalExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitTerminal(TerminalExpression node) {
    visit(node);
    return null;
  }

  @override
  T visitZeroOrMore(ZeroOrMoreExpression node) {
    visit(node);
    return null;
  }
}
