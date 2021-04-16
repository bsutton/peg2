part of '../../expressions.dart';

class ZeroOrMoreExpression extends SuffixExpression {
  @override
  final ExpressionKind kind = ExpressionKind.zeroOrMore;

  ZeroOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '*';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitZeroOrMore(this);
  }
}
