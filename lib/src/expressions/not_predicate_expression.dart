part of '../../expressions.dart';

class NotPredicateExpression extends PrefixExpression {
  @override
  final ExpressionKind kind = ExpressionKind.notPredicate;

  NotPredicateExpression(Expression expression) : super(expression);

  @override
  String get prefix => '!';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitNotPredicate(this);
  }
}
