part of '../../grammar_fa_analyzers.dart';

class GrammarFaAnalyzer {
  ParserGeneratorOptions _options;

  void analyze(ParserGeneratorOptions options, DfaState dfa,
      List<String> errors, List<String> warnings) {
    _options = options;
    _visit(dfa, {});
  }

  void _analyzeMemoization(DfaState state) {
    final starts = state.starts;
    final symbols = starts.whereType<SymbolExpression>();
    final groupedByRule = symbols.groupBy((e) => e.expression.rule);
    for (final ruleGroup in groupedByRule) {
      final rule = ruleGroup.key;
      final symbols = ruleGroup.toList();
      if (symbols.length > 1) {
        // Bug in Dart analyzer (unnecessary_lambdas)
        // [Don't create a lambda when a tear-off will do.dart(unnecessary_lambdas)]
        // Suggestion: Analyzer should not warn if used generic lambda
        final groupedBySequence =
            symbols.groupBy((e) => _getUpper<SequenceExpression>(e));
        final filtered = <SymbolExpression>[];
        for (final sequenceGroup in groupedBySequence) {
          filtered.add(sequenceGroup.first);
        }

        if (filtered.length > 1) {
          if (!_isAllLast(filtered)) {
            for (final symbol in filtered) {
              rule.memoizationRequests.add(symbol);
              //print('${state.id}: ${symbol.rule}.${symbol}(${symbol.id}) :: [${rule}] ${symbol.parent}');
              symbol.memoize = true;
            }
          }
        }
      }
    }
  }

  // TODO: remove?
  // ignore: unused_element
  T _geFirst<T>(Expression expression) {
    var parent = expression.parent;
    while (true) {
      if (parent == null) {
        break;
      }

      if (parent is T) {
        return parent as T;
      }

      parent = parent.parent;
    }

    return null;
  }

  T _getUpper<T>(Expression expression) {
    var parent = expression.parent;
    T last;
    while (true) {
      if (parent == null) {
        break;
      }

      if (parent is T) {
        last = parent as T;
      }

      parent = parent.parent;
    }

    return last;
  }

  bool _isAllLast(Iterable<Expression> expressions) {
    var lastCount = 0;
    var count = 0;
    for (final expression in expressions) {
      count++;
      if (_isLast(expression)) {
        lastCount++;
      }
    }

    return lastCount == count;
  }

  // TODO: remove?
  // ignore: unused_element
  bool _isEqual(Expression e1, Expression e2) {
    if (e1 == null && e2 == null) {
      return false;
    }

    return e1 == e2;
  }

  bool _isLast(Expression expression) {
    final parent = expression.parent;
    while (expression != parent) {
      if (!expression.isLast) {
        return false;
      }

      expression = expression.parent;
    }

    return true;
  }

  void _visit(DfaState state, Set<DfaState> processed) {
    if (!processed.add(state)) {
      return;
    }

    for (final group in state.transitions.groups) {
      for (final state in group.key) {
        _visit(state, processed);
      }
    }

    if (_options.memoize) {
      _analyzeMemoization(state);
    }
  }
}
