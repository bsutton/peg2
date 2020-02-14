part of '../../expressions.dart';

class ZeroOrMoreExpression extends SuffixExpression {
  ZeroOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '*';

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitZeroOrMore(this);
  }
}
