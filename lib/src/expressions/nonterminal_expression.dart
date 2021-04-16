part of '../../expressions.dart';

class NonterminalExpression extends SymbolExpression {
  @override
  final ExpressionKind kind = ExpressionKind.nonterminal;

  NonterminalExpression(String name) : super(name);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitNonterminal(this);
  }
}
