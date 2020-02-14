part of '../../grammar.dart';

class ProductionRule {
  OrderedChoiceExpression expression;

  final ProductionRuleKind kind;

  int id;

  final String name;

  String returnType;

  ProductionRule(this.name, this.kind, this.expression, this.returnType) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (kind == null) {
      throw ArgumentError.notNull('kind');
    }

    if (expression == null) {
      throw ArgumentError.notNull('expression');
    }
  }

  @override
  String toString() {
    return name;
  }
}