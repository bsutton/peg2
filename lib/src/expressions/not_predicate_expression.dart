part of '../../expressions.dart';

class NotPredicateExpression extends PrefixExpression {
  NotPredicateExpression(Expression expression) : super(expression);

  @override
  ExpressionKind get kind => ExpressionKind.notPredicate;

  @override
  String get prefix => '!';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitNotPredicate(this);
  }
}
