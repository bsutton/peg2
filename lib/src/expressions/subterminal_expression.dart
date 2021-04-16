part of '../../expressions.dart';

class SubterminalExpression extends SymbolExpression {
  @override
  final ExpressionKind kind = ExpressionKind.subterminal;

  SubterminalExpression(String name) : super(name);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitSubterminal(this);
  }
}
