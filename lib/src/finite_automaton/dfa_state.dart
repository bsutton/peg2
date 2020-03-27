part of '../../finite_automaton.dart';

class DfaState extends State<DfaState, NfaState> {
  @override
  final String kind = 'dfa';

  DfaState(int id) : super(id);
}
