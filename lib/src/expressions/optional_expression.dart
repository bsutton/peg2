part of '../../expressions.dart';

class OptionalExpression extends SuffixExpression {
  OptionalExpression(Expression expression) : super(expression);

  @override
  String get suffix => '?';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitOptional(this);
  }
}
