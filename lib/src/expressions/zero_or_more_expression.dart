part of '../../expressions.dart';

class ZeroOrMoreExpression extends SuffixExpression {
  ZeroOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '*';

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitZeroOrMore(this);
  }
}
