part of '../../expressions.dart';

class NonterminalExpression extends Expression {
  final String name;

  Expression expression;

  NonterminalExpression(this.name) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.isEmpty) {
      throw ArgumentError('Name should not be emptry');
    }
  }

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitNonterminal(this);
  }

  @override
  String toString() => name;
}
