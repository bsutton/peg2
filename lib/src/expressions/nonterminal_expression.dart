part of '../../expressions.dart';

class NonterminalExpression extends SymbolExpression {
  NonterminalExpression(String name) : super(name);

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitNonterminal(this);
  }
}
