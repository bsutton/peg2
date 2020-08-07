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
  T accept<T>(ExpressionVisitor<T> visitor) {
    return expression.accept(visitor);
  }

  @override
  void visitChildren<T>(ExpressionVisitor<T> visitor) {
    expression.accept(visitor);
  }
}
