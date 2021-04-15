part of '../../expressions.dart';

class NonterminalExpression extends SymbolExpression {
  NonterminalExpression(String name) : super(name);

  @override
  ExpressionKind get kind => ExpressionKind.nonterminal;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitNonterminal(this);
  }
}
