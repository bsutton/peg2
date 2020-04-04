part of '../../finite_automaton.dart';

class ExpressionToTokenizedEnfaConverter extends ExpressionToEnfaConverterBase {
  static const magicNumber = 0x200000;

  @override
  void separate(SymbolExpression node, EnfaState prev, EnfaState next) {
    final list = SparseBoolList();
    final marker = magicNumber + node.id;
    final range = GroupedRangeList(marker, marker, true);
    list.addGroup(range);
    final transitions = prev.transitions;
    for (final group in transitions.getAllSpace(range)) {
      var key = group.key;
      key ??= [];
      if (!key.contains(next)) {
        key.add(next);
      }

      if (group.key == null) {
        final start = group.start;
        final end = group.end;
        final newGroup = GroupedRangeList(start, end, key);
        transitions.addGroup(newGroup);
      }
    }
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final s0 = _last;
    _start(node);
    final s1 = _createState();
    final startCharacters = SparseBoolList();
    final token = node.id;
    final group = GroupedRangeList(token, token, true);
    startCharacters.addGroup(group);
    _addTransitions(s0, startCharacters, s1);
    _end(node, s1);
  }
}
