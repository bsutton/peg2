part of '../../expressions.dart';

class OneOrMoreExpression extends SuffixExpression {
  OneOrMoreExpression(Expression expression) : super(expression);

  @override
  String get suffix => '+';

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitOneOrMore(this);
  }
}
