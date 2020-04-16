part of '../../finite_automaton.dart';

class NfaToDfaConverter {
  Map<int, List<NfaState>> _cachedStateLists;

  Set<DfaState> _dfaStates;

  int _id;

  Set<DfaState> _pending;

  DfaState convert(NfaState nfa) {
    _cachedStateLists = {};
    _dfaStates = {};
    _id = 0;
    _pending = {};
    final result = _addNewState({nfa});
    while (_pending.isNotEmpty) {
      final state = _getNext();

      // Movements
      // final movementsFromNfaStates =
      //     <Expression, List<GroupedRangeList<NfaState>>>{};
      // for (final nfaState in state.states) {
      //   final nfaStateMovements = nfaState.movements;
      //   for (final expression in nfaStateMovements.keys) {
      //     var dest = movementsFromNfaStates[expression];
      //     if (dest == null) {
      //       dest = [];
      //       movementsFromNfaStates[expression] = dest;
      //     }

      //     final src = nfaStateMovements[expression];
      //     dest.addAll(src);
      //   }
      // }

      //final stateMovements = state.movements;
      final stateTransitions = state.transitions;
      final nfaStates = SparseList<Set<NfaState>>();
      for (final nfaState in state.states) {
        for (final group in nfaState.transitions.groups) {
          for (final src in nfaStates.getAllSpace(group)) {
            var key = src.key;
            if (key == null) {
              key = {};
              key.addAll(group.key);
            } else {
              key = key.toSet();
              key.addAll(group.key);
            }

            final start = src.start;
            final end = src.end;
            final dest = GroupedRangeList(start, end, key);
            nfaStates.addGroup(dest);
          }
        }
      }

      for (final group in nfaStates.groups) {
        final start = group.start;
        final end = group.end;
        final key = group.key;
        final newState = _addNewState(key);
        final transition =
            GroupedRangeList<List<DfaState>>(start, end, [newState]);
        stateTransitions.addGroup(transition);

        // Movements
        // for (final expression in movementsFromNfaStates.keys) {
        //   final movements = movementsFromNfaStates[expression];
        //   if (movements != null) {
        //     for (final movement in movements) {
        //       if (newState.states.contains(movement.key)) {
        //         final intersection = movement.intersection(group);
        //         if (intersection != null) {
        //           final start = intersection.start;
        //           final end = intersection.end;
        //           final expressionMovement =
        //               GroupedRangeList(start, end, newState);
        //           var expressionMovements = stateMovements[expression];
        //           if (expressionMovements == null) {
        //             expressionMovements = [];
        //             stateMovements[expression] = expressionMovements;
        //           }

        //           expressionMovements.add(expressionMovement);
        //         }
        //       }
        //     }
        //   }
        // }
      }
    }

    _free(result, {});
    return result;
  }

  DfaState _addNewState(Set<NfaState> states) {
    final states0 = states.toList();
    states0.sort((x, y) => x.id.compareTo(y.id));
    for (final state in _dfaStates) {
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

    final result = DfaState(_id++);
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

    _dfaStates.add(result);
    _pending.add(result);
    return result;
  }

  void _free(DfaState state, Set<DfaState> processed) {
    if (!processed.add(state)) {
      return;
    }

    for (final state in state.states) {
      state.starts.clear();
      state.active.clear();
      state.ends.clear();
    }

    for (final group in state.transitions.groups) {
      final states = group.key;
      for (final state in states) {
        _free(state, processed);
      }
    }
  }

  DfaState _getNext() {
    final result = _pending.first;
    _pending.remove(result);
    return result;
  }
}
