part of '../../expressions.dart';

class SubterminalExpression extends SymbolExpression {
  SubterminalExpression(String name) : super(name);

  @override
  ExpressionKind get kind => ExpressionKind.subterminal;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitSubterminal(this);
  }
}
