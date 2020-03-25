part of '../../expressions.dart';

abstract class SymbolExpression extends Expression {
  final String name;

  OrderedChoiceExpression expression;

  SymbolExpression(this.name) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.isEmpty) {
      throw ArgumentError('Name should not be emptry');
    }
  }

  @override
  String toString() => name;
}
