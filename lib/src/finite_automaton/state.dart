part of '../../finite_automaton.dart';

abstract class State<TParent, TChild> {
  bool accept = false;

  final active = <Expression>{};

  final ends = <Expression>{};

  final id;

  final starts = <Expression>{};

  final states = <TChild>{};

  final transitions = SparseList<TParent>();

  State(this.id);

  String get kind;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(kind);
    sb.write(' ');
    sb.write(id);
    sb.write(': (');
    sb.write(states.toList()
      ..sort()
      ..join(', '));
    sb.write(')');
    return sb.toString();
  }
}
