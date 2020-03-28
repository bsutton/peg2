part of '../../finite_automaton.dart';

class AlphabetResolver {
  SparseList<bool> _list;

  Set<ENfaState> _processed;

  SparseBoolList resolve(ENfaState state) {
    _list = SparseList<bool>(equals: (x, y) => false);
    _processed = {};
    _visitState(state);
    final result = SparseBoolList();
    for (final range in _list.groups) {
      result.addGroup(range);
    }

    return result;
  }

  void _addGroup(SparseList<bool> list, GroupedRangeList<bool> range) {
    final group = GroupedRangeList<bool>(range.start, range.end, true);
    list.addGroup(group);
  }

  void _resolve(SparseList<bool> list, GroupedRangeList<bool> range) {
    final ranges = list.getAllSpace(range);
    for (final src in ranges) {
      final start = src.start;
      final end = src.end;
      final key = src.key;
      if (key == null) {
        final dest = GroupedRangeList<bool>(start, end, true);
        list.addGroup(dest);
      } else if (start != range.start || end != range.end) {
        final keyRange = GroupedRangeList<bool>(start, end, true);
        final intersection = range.intersection(keyRange);
        _addGroup(list, intersection);
        for (final range in range.subtract(intersection)) {
          _addGroup(list, range);
        }

        for (final range in keyRange.subtract(intersection)) {
          _addGroup(list, range);
        }
      } else {
        _addGroup(list, src);
      }
    }
  }

  void _visitState(ENfaState state) {
    if (!_processed.add(state)) {
      return;
    }

    for (final state in state.states) {
      _visitState(state);
    }

    for (final group in state.transitions.groups) {
      _visitState(group.key);
      final range = GroupedRangeList<bool>(group.start, group.end, true);
      _resolve(_list, range);
    }
  }
}
