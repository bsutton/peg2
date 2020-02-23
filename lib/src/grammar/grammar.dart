part of '../../grammar.dart';

class Grammar {
  int expressionCount;

  final String globals;

  Map<String, ProductionRule> mapOfRules;

  final String members;

  List<ProductionRule> rules;

  ProductionRule start;

  Grammar(List<ProductionRule> rules, this.globals, this.members) {
    if (rules == null) {
      throw ArgumentError.notNull('rules');
    }

    if (rules.isEmpty) {
      throw ArgumentError('List of rules should not be empty');
    }

    // TDDO: Find start rule
    start = rules.first;
    mapOfRules = <String, ProductionRule>{};
    this.rules = <ProductionRule>[];
    var id = 0;
    for (var rule in rules) {
      if (rule == null) {
        throw ArgumentError('rules');
      }

      rule.id = id++;
      this.rules.add(rule);
      final name = rule.name;
      if (mapOfRules.containsKey(name)) {
        throw StateError('Duplicate rule name: ${name}');
      }

      mapOfRules[rule.name] = rule;
    }

    _initialize();
  }

  void _initialize() {
    final expressionInitializer = ExpressionInitializer();
    expressionInitializer.initialize(this);
    final expressionTransformationInitializer =
        ExpressionTransformationInitializer();
    expressionTransformationInitializer.initialize(rules);

    final expressionProductivenessResolver = ExpressionProductivenessResolver();
    expressionProductivenessResolver.resolve(this);

    final expressionReturnTypeResolver = ExpressionReturnTypeResolver();
    expressionReturnTypeResolver.resolve(rules);
  }
}
