part of '../../expressions.dart';

class AndPredicateExpression extends PrefixExpression {
  AndPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '&';

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitAndPredicate(this);
  }
}
