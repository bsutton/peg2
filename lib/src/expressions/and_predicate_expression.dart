part of '../../expressions.dart';

class AndPredicateExpression extends PrefixExpression {
  @override
  final ExpressionKind kind = ExpressionKind.andPredicate;

  AndPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '&';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitAndPredicate(this);
  }
}
