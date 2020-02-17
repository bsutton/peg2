part of '../../expression_transformers.dart';

class ExpressionTransformationInitializer extends ExpressionVisitor {
  bool _hasModifications;

  void initialize(List<ProductionRule> rules) {
    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        rule.expression.accept(this);
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCapture(CaptureExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOptional(OptionalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitSequence(SequenceExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    node.visitChildren(this);
  }
}
