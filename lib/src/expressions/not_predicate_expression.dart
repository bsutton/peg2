part of '../../expressions.dart';

class NotPredicateExpression extends PrefixExpression {
  NotPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '!';

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitNotPredicate(this);
  }
}
