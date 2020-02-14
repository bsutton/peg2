part of '../../expressions.dart';

abstract class SingleExpression extends Expression {
  Expression expression;

  SingleExpression(this.expression) {
    if (expression == null) {
      throw ArgumentError.notNull('expression');
    }

    expression.parent = this;
  }

  @override
  dynamic visitChildren(ExpressionVisitor visitor) {
    expression.accept(visitor);
    return null;
  }
}