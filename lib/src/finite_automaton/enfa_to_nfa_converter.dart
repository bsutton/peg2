part of '../../finite_automaton.dart';

class ENfaToNfaConverter {
  Map<int, List<EnfaState>> _cachedStateLists;

  int _id;

  Set<NfaState> _nfaStates;

  Set<NfaState> _pending;

  NfaState convert(EnfaState enfa) {
    _cachedStateLists = {};
    _id = 0;
    _nfaStates = {};
    _pending = {};
    final epsilonMoves = <EnfaState>{};
    _epsilonClosure(enfa, epsilonMoves);
    final result = _addNewState(epsilonMoves);
    while (_pending.isNotEmpty) {
      final state = _getNext();
      final epsilonMoves = <EnfaState>{};
      for (final enfaState in state.states) {
        _epsilonClosure(enfaState, epsilonMoves);
      }

      final stateTransitions = state.transitions;
      for (final epsilonMove in epsilonMoves) {
        for (final group in epsilonMove.transitions.groups) {
          final epsilonMoves = <EnfaState>{};
          for (final move in group.key) {
            _epsilonClosure(move, epsilonMoves);
          }

          if (epsilonMoves.isNotEmpty) {
            final newState = _addNewState(epsilonMoves);
            final groups = stateTransitions.getAllSpace(group);
            for (final group in groups) {
              var key = group.key;
              key ??= [];
              if (!key.contains(newState)) {
                key.add(newState);
              }

              if (group.key == null) {
                final start = group.start;
                final end = group.end;
                final transition = GroupedRangeList(start, end, key);
                stateTransitions.addGroup(transition);
              }
            }
          }
        }
      }
    }

    return result;
  }

  NfaState _addNewState(Set<EnfaState> states) {
    final states0 = states.toList();
    states0.sort((x, y) => x.id.compareTo(y.id));
    for (final state in _nfaStates) {
      final states1 = _cachedStateLists[state.id];
      if (states0.length == states1.length) {
        var found = true;
        for (var i = 0; i < states0.length; i++) {
          if (states0[i].id != states1[i].id) {
            found = false;
            break;
          }
        }

        if (found) {
          return state;
        }
      }
    }

    final result = NfaState(_id++);
    _cachedStateLists[result.id] = states0;
    result.states.addAll(states0);
    for (var state in states) {
      result.starts.addAll(state.starts);
      result.active.addAll(state.active);
      result.ends.addAll(state.ends);
      if (state.isFinal) {
        result.isFinal = true;
      }
    }

    _nfaStates.add(result);
    _pending.add(result);
    return result;
  }

  void _epsilonClosure(EnfaState state, Set<EnfaState> emoves) {
    if (!emoves.add(state)) {
      return;
    }

    for (final emove in state.states) {
      _epsilonClosure(emove, emoves);
    }
  }

  NfaState _getNext() {
    final result = _pending.first;
    _pending.remove(result);
    return result;
  }
}
