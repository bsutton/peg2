part of '../../expressions.dart';

class OptionalExpression extends SuffixExpression {
  OptionalExpression(Expression expression) : super(expression);

  @override
  String get suffix => '?';

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitOptional(this);
  }
}
