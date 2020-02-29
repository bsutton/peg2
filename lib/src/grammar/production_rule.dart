part of '../../grammar.dart';

class ProductionRule {
  final Set<ProductionRule> allCallees = {};

  final Set<ProductionRule> allCallers = {};

  final Set<ProductionRule> directCallees = {};

  final Set<ProductionRule> directCallers = {};

  final Set<SymbolExpression> callers = {};

  final OrderedChoiceExpression expression;

  bool isStartingRule;

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
