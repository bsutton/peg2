part of '../../expressions.dart';

class StartExpression extends Expression {
  final expression;

  StartExpression(this.expression);

  @override
  void accept(ExpressionVisitor visitor) {
    throw UnsupportedError('');
  }

  @override
  String toString() {
    return 'START($expression)';
  }
}
