part of '../../grammar.dart';

class ProductionRule {
  final Set<ProductionRule> allCallees = {};

  final Set<SymbolExpression> allCallers = {};

  final Set<ProductionRule> directCallees = {};

  final Set<SymbolExpression> directCallers = {};

  final OrderedChoiceExpression expression;

  bool? isStartingRule;

  final ProductionRuleKind kind;

  int? id;

  final Set<SymbolExpression> memoizationRequests = {};

  final String name;

  String? returnType;

  ProductionRule(this.name, this.kind, this.expression, this.returnType);

  @override
  String toString() {
    return name;
  }
}
