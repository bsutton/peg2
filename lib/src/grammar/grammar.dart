part of '../../grammar.dart';

class Grammar {
  final errors = <String>[];

  Map<int, Expression> expressionMap;

  final String globals;

  final String members;

  List<ProductionRule> rules;

  Map<String, ProductionRule> ruleMap;

  ProductionRule start;

  final warnings = <String>[];

  Grammar(List<ProductionRule> rules, this.globals, this.members) {
    if (rules == null) {
      throw ArgumentError.notNull('rules');
    }

    if (rules.isEmpty) {
      throw ArgumentError('List of rules should not be empty');
    }

    final duplicates = <String>{};
    ruleMap = <String, ProductionRule>{};
    this.rules = <ProductionRule>[];
    var id = 0;
    for (var rule in rules) {
      if (rule == null) {
        throw ArgumentError('rules');
      }

      rule.id = id++;
      this.rules.add(rule);
      final name = rule.name;
      if (ruleMap.containsKey(name)) {
        duplicates.add(name);
      }

      ruleMap[rule.name] = rule;
    }

    for (final name in duplicates) {
      errors.add('Duplicate rule name: ${name}');
    }

    _initialize();
  }

  void _initialize() {
    final grammarInitializer0 = GrammarInitializer0();
    grammarInitializer0.initialize(this, errors, warnings);

    final grammarInitializer1 = GrammarInitializer1();
    grammarInitializer1.initialize(this, errors, warnings);
  }
}
