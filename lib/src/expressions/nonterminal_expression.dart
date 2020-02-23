part of '../../expressions.dart';

class NonterminalExpression extends SymbolExpression {
  NonterminalExpression(String name) : super(name);

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitNonterminal(this);
  }
}
