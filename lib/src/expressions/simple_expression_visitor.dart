part of '../../expressions.dart';

class SimpleExpressionVisitor extends ExpressionVisitor {
  void visit(Expression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitCapture(CaptureExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitOptional(OptionalExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitSequence(SequenceExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitTerminal(TerminalExpression node) {
    visit(node);
    return null;
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    visit(node);
    return null;
  }
}
