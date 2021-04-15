part of '../../expressions.dart';

class ZeroOrMoreExpression extends SuffixExpression {
  ZeroOrMoreExpression(Expression expression) : super(expression);

  @override
  ExpressionKind get kind => ExpressionKind.zeroOrMore;

  @override
  String get suffix => '*';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitZeroOrMore(this);
  }
}
