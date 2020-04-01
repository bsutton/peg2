part of '../../finite_automaton.dart';

abstract class State<TSelf extends State<TSelf, TState>,
    TState extends State<dynamic, dynamic>> {
  final active = <Expression>{};

  final ends = <Expression>{};

  final int id;

  bool isFinal = false;

  final starts = <Expression>{};

  final states = <TState>{};

  final transitions = SparseList<List<TSelf>>();

  State(this.id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) {
    if (other is TSelf) {
      return id == other.id;
    }

    return false;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    if (isFinal) {
      sb.write('V');
    }

    sb.write(id);
    if (states.isNotEmpty) {
      sb.write('(');
      final list = <String>[];
      for (final state in states) {
        list.add('${state.id}');
      }

      sb.write(list.join(', '));
      sb.write(')');
    }

    return sb.toString();
  }
}
