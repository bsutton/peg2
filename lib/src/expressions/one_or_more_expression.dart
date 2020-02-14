part of '../../expressions.dart';

class OneOrMoreExpression extends SuffixExpression {
  OneOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '+';

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitOneOrMore(this);
  }
}
