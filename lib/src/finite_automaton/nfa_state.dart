part of '../../finite_automaton.dart';

class NfaState extends State<NfaState, ENfaState> {
  @override
  final String kind = 'nfa';

  NfaState(int id) : super(id);
}
