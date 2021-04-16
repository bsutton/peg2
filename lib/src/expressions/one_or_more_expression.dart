part of '../../expressions.dart';

class OneOrMoreExpression extends SuffixExpression {
  @override
  final ExpressionKind kind = ExpressionKind.oneOrMore;

  OneOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '+';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitOneOrMore(this);
  }
}
