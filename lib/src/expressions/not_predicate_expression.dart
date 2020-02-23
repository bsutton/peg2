part of '../../expressions.dart';

class NotPredicateExpression extends PrefixExpression {
  NotPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '!';

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitNotPredicate(this);
  }
}
