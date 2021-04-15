part of '../../expressions.dart';

class OneOrMoreExpression extends SuffixExpression {
  OneOrMoreExpression(Expression expression) : super(expression);

  @override
  ExpressionKind get kind => ExpressionKind.oneOrMore;

  @override
  String get suffix => '+';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitOneOrMore(this);
  }
}
