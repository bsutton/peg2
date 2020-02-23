part of '../../expressions.dart';

class OptionalExpression extends SuffixExpression {
  OptionalExpression(Expression expression) : super(expression);

  @override
  String get suffix => '?';

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitOptional(this);
  }
}
