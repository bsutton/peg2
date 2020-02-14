part of '../../expressions.dart';

class SubterminalExpression extends Expression {
  final String name;

  Expression expression;

  SubterminalExpression(this.name) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.isEmpty) {
      throw ArgumentError('Name should not be emptry');
    }
  }

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitSubterminal(this);
  }

  @override
  String toString() => name;
}
