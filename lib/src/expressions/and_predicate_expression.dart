part of '../../expressions.dart';

class AndPredicateExpression extends PrefixExpression {
  AndPredicateExpression(Expression expression) : super(expression);

  @override
  ExpressionKind get kind => ExpressionKind.andPredicate;

  @override
  String get prefix => '&';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitAndPredicate(this);
  }
}
