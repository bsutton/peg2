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

      // Movements
      // final movementsFromEnfaStates =
      //     <Expression, List<GroupedRangeList<EnfaState>>>{};
      // for (final enfaState in state.states) {
      //   final enfaStateMovements = enfaState.movements;
      //   for (final expression in enfaStateMovements.keys) {
      //     var dest = movementsFromEnfaStates[expression];
      //     if (dest == null) {
      //       dest = [];
      //       movementsFromEnfaStates[expression] = dest;
      //     }

      //     final src = enfaStateMovements[expression];
      //     dest.addAll(src);
      //   }
      // }

      //final stateMovements = state.movements;
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
              if (key == null) {
                key = [newState];
              } else {
                if (!key.contains(newState)) {
                  key = key.toList();
                  key.add(newState);
                }
              }

              final start = group.start;
              final end = group.end;
              final transition = GroupedRangeList(start, end, key);
              stateTransitions.addGroup(transition);
            }

            // Movements
            // for (final expression in movementsFromEnfaStates.keys) {
            //   final movements = movementsFromEnfaStates[expression];
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
      }
    }

    _free(result, {});
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

  void _free(NfaState state, Set<NfaState> processed) {
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

  NfaState _getNext() {
    final result = _pending.first;
    _pending.remove(result);
    return result;
  }
}
