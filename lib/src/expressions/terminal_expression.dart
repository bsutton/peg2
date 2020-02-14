part of '../../expressions.dart';

class TerminalExpression extends Expression {
  final String name;

  Expression expression;

  TerminalExpression(this.name) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.isEmpty) {
      throw ArgumentError('Name should not be emptry');
    }
  }

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitTerminal(this);
  }

  @override
  String toString() => name;
}
