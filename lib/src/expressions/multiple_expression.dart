part of '../../expressions.dart';

abstract class MultipleExpression<E extends Expression> extends Expression {
  List<E> expressions;

  MultipleExpression(List<E> expressions) {
    if (expressions == null) {
      throw ArgumentError.notNull('expressions');
    }

    if (expressions.isEmpty) {
      throw ArgumentError('expressions');
    }

    this.expressions = [];
    for (var expression in expressions) {
      if (expression == null) {
        throw ArgumentError('expressions');
      }

      if (expression is! E) {
        throw ArgumentError('expressions');
      }

      expression.parent = this;
      this.expressions.add(expression);
    }
  }

  @override
  dynamic visitChildren(ExpressionVisitor visitor) {
    for (var expression in expressions) {
      expression.accept(visitor);
    }

    return null;
  }
}
