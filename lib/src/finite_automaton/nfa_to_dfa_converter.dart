part of '../../finite_automaton.dart';

class NfaToDfaConverter {
  Set<State> _dfas;

  Map<State, Set<State>> _dfaNfa;

  int _id;

  Map<State, State> _nfaDfa;

  Set<State> _pending;

  Set<State> _processed;

  State convert(State nfa) {
    _dfas = {};
    _dfaNfa = {};
    _id = 0;
    _nfaDfa = {};
    _pending = {};
    _processed = {};
    _addToPending(nfa);
    while (true) {
      if (_pending.isEmpty) {
        break;
      }

      final nfa = _pending.first;
      _removeFromPending(nfa);
      final dfa = _addNfaToDfa(nfa);
      for (final epsilon in nfa.epsilon) {
        _addEpsilons(dfa, epsilon);
      }

      final nfas = _getDfaNfas(dfa);
      final starts = dfa.starts;
      final active = dfa.active;
      final ends = dfa.ends;
      for (final nfa in nfas) {
        _printNfa(nfa);
        starts.addAll(nfa.starts);
        active.addAll(nfa.active);
        ends.addAll(nfa.ends);
        final transitions = nfa.transitions;
        for (final group in transitions.groups) {
          final key = group.key;
          //_addNfaToDfa(key);
          _addToPending(key);
        }
      }

      _printNfa(dfa);
    }

    return null;
  }

  void _addEpsilons(State dfa, State nfa) {
    final nfas = _getDfaNfas(dfa);
    if (!nfas.add(nfa)) {
      return;
    }

    for (final epsilon in nfa.epsilon) {
      _addEpsilons(dfa, epsilon);
    }
  }

  State _addNfaToDfa(State nfa) {
    var dfa = _nfaDfa[nfa];
    if (dfa != null) {
      return dfa;
    }

    dfa = State(_id++);
    _dfas.add(dfa);
    _nfaDfa[nfa] = dfa;
    final nfas = _getDfaNfas(dfa);
    nfas.add(nfa);
    return dfa;
  }

  void _addToPending(State nfa) {
    if (_processed.contains(nfa)) {
      return;
    }

    _pending.add(nfa);
  }

  Set<State> _getDfaNfas(State dfa) {
    var nfas = _dfaNfa[dfa];
    if (nfas == null) {
      nfas = {};
      _dfaNfa[dfa] = nfas;
    }

    return nfas;
  }

  void _printNfa(State nfa) {
    void writeExpr(StringBuffer sb, Iterable<Expression> expressions) {
      for (final expression in expressions) {
        sb.write(expression.rule.name);
        sb.write(' ');
        sb.write(expression.runtimeType);
        sb.write(': ');
        sb.writeln(expression);
      }
    }

    final sb = StringBuffer();
    sb.write('state: ');
    sb.writeln(nfa.id);
    sb.writeln('starts: ');
    writeExpr(sb, nfa.starts);
    sb.writeln('active: ');
    writeExpr(sb, nfa.active);
    sb.writeln('ends: ');
    writeExpr(sb, nfa.ends);
    sb.writeln('===========');
    print(sb);
  }

  void _removeFromPending(State nfa) {
    if (!_pending.remove(nfa)) {
      throw StateError('Pending states does not contains the specified state ');
    }

    _processed.add(nfa);
  }
}
