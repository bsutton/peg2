part of '../../finite_automaton.dart';

class ENfaState extends State<ENfaState, ENfaState> {
  @override
  final String kind = 'ε-nfa';

  ENfaState(int id) : super(id);
}
