part of '../../grammar.dart';

class Grammar {
  final errors = <String>[];

  int expressionCount;

  final String globals;

  Map<String, ProductionRule> mapOfRules;

  final String members;

  List<ProductionRule> rules;

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
        duplicates.add(name);
      }

      mapOfRules[rule.name] = rule;
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

    if (errors.isEmpty) {
      final String Function(State<dynamic, dynamic>) _label = null;
      final expressionToEnfaConverter = ExpressionToEnfaConverter();
      final enfa0 =
          expressionToEnfaConverter.convert(start.expression, _separate0);
      final enfa1 =
          expressionToEnfaConverter.convert(start.expression, _separate1);
      final faToDotConverter = FaToDotConverter();
      final enfaDot0 = faToDotConverter.convert(enfa0, true, _label);
      final enfaDot1 = faToDotConverter.convert(enfa1, true, _label);
      File('enfa0.dot').writeAsStringSync(enfaDot0);
      File('enfa1.dot').writeAsStringSync(enfaDot1);
      final enfaToNfaConverter = ENfaToNfaConverter();
      final nfa0 = enfaToNfaConverter.convert(enfa0);
      final nfa1 = enfaToNfaConverter.convert(enfa1);
      final nfaDot0 = faToDotConverter.convert(nfa0, false, _label);
      final nfaDot1 = faToDotConverter.convert(nfa1, false, _label);
      File('nfa0.dot').writeAsStringSync(nfaDot0);
      File('nfa1.dot').writeAsStringSync(nfaDot1);
      final nfaToDfaConverter = NfaToDfaConverter();
      final dfa0 = nfaToDfaConverter.convert(nfa0);
      final dfa1 = nfaToDfaConverter.convert(nfa1);
      final dfaDot0 = faToDotConverter.convert(dfa0, false, _label);
      final dfaDot1 = faToDotConverter.convert(dfa1, false, _label);
      File('dfa0.dot').writeAsStringSync(dfaDot0);
      File('dfa1.dot').writeAsStringSync(dfaDot1);
      final grammarFaAnalyzer = GrammarFaAnalyzer();
      grammarFaAnalyzer.analyze(dfa0, errors, warnings);
      final memoizationRequestsOptimizer = MemoizationRequestsOptimizer();
      memoizationRequestsOptimizer.optimize(rules);
    }
  }

  String _label(State<dynamic, dynamic> state) {
    String write(Iterable<Expression> expressions) {
      final list = <String>[];
      for (final expression in expressions) {
        final sb = StringBuffer();
        sb.write('[');
        sb.write(expression.rule.name);
        sb.write('(');
        sb.write(expression.runtimeType.toString().substring(0, 3));
        sb.write(' ');
        sb.write(expression.id);
        sb.write(') ');
        var str = expression.toString();
        str = str.replaceAll(r'\', r'\\');
        str = str.replaceAll('"', r'\"');
        sb.write(str);
        sb.write(']');
        list.add(sb.toString());
      }

      return list.join(', ');
    }

    final sb = StringBuffer();
    if (state.isFinal) {
      sb.write('V');
    }

    sb.write(state.id);
    sb.write(r'\n');
    if (state.starts.isNotEmpty) {
      sb.write('starts: ');
      sb.write(write(state.starts));
      sb.write(r'\n');
    }

    if (state.active.isNotEmpty) {
      sb.write('active: ');
      sb.write(write(state.active));
      sb.write(r'\n');
    }

    if (state.ends.isNotEmpty) {
      sb.write('ends: ');
      sb.write(write(state.ends));
      sb.write(r'\n');
    }

    return sb.toString();
  }

  void _separate0(SymbolExpression node, EnfaState prev, EnfaState next) {
    // Epsilon move
    prev.states.add(next);
  }

  void _separate1(SymbolExpression node, EnfaState prev, EnfaState next) {
    final list = SparseBoolList();
    final marker = 0x110000 + node.id;
    final range = GroupedRangeList(marker, marker, true);
    list.addGroup(range);
    final transitions = prev.transitions;
    for (final group in transitions.getAllSpace(range)) {
      var key = group.key;
      key ??= [];
      if (!key.contains(next)) {
        key.add(next);
      }

      if (group.key == null) {
        final start = group.start;
        final end = group.end;
        final newGroup = GroupedRangeList(start, end, key);
        transitions.addGroup(newGroup);
      }
    }
  }
}
