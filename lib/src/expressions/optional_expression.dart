part of '../../expressions.dart';

class OptionalExpression extends SuffixExpression {
  OptionalExpression(Expression expression) : super(expression);

  @override
  ExpressionKind get kind => ExpressionKind.optional;

  @override
  String get suffix => '?';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitOptional(this);
  }
}
