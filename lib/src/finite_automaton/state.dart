part of '../../finite_automaton.dart';

abstract class State<TParent, TChild> extends Comparable<State> {
  bool accept = false;

  final active = <Expression>{};

  final ends = <Expression>{};

  final int id;

  final starts = <Expression>{};

  final states = <TChild>{};

  final transitions = SparseList<TParent>();

  State(this.id);

  String get kind;

  @override
  int compareTo(State other) {
    if (other == null) {
      return 1;
    }

    return id.compareTo(other.id);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(id);
    sb.write(':');
    if (states.isNotEmpty) {
      sb.write('(');
      final list = <String>[];
      for (final state in states.toList()..sort()) {
        if (state is State) {
          list.add(state.id.toString());
        } else {
          list.add('?');
        }
      }

      sb.write(list.join(', '));
      sb.write(')');
    }

    return sb.toString();
  }
}
