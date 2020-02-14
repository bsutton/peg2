part of '../../expressions.dart';

class AndPredicateExpression extends PrefixExpression {
  AndPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '&';

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitAndPredicate(this);
  }
}
