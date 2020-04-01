part of '../../grammar_analyzers.dart';

class GrammarFaAnalyzer {
  void analyze(DfaState dfa, List<String> errors, List<String> warnings) {
    _visit(dfa, {});
  }

  void _analyzeMemoization(DfaState state) {
    final starts = state.starts;
    final symbols = starts.whereType<SymbolExpression>();
    final grouped = groupBy(symbols, (SymbolExpression e) => e.expression.rule);
    for (final rule in grouped.keys) {
      final symbols = grouped[rule];
      if (symbols.length > 1) {
        final canditates = symbols.toList();
        for (final s1 in canditates) {
          for (final s2 in canditates) {
            if (s1 != s2) {
              final upper1 = _getUpper<SequenceExpression>(s1);
              final upper2 = _getUpper<SequenceExpression>(s2);
              if (_isEqual(upper1, upper2)) {
                symbols.remove(s1);
                symbols.remove(s2);
              }
            }
          }
        }

        print('------------');
        if (!_isAllLast(symbols)) {
          for (final symbol in symbols) {
            rule.memoizationRequests.add(symbol);
            print(
                '${state.id}: ${symbol.rule}.${symbol}(${symbol.id}) :: [${rule}] ${symbol.parent}');
            symbol.memoize = true;
          }
        }
      }
    }
  }

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

    _analyzeMemoization(state);
  }
}
