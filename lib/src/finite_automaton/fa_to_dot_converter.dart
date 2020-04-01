part of '../../finite_automaton.dart';

class FaToDotConverter<S extends State<dynamic, dynamic>> {
  bool _hasEpsilonMoves;

  String Function(S) _label;

  StringBuffer _sb;

  String convert(S state, bool hasEpsilonMoves,
      [String Function(S) stateLabel]) {
    _hasEpsilonMoves = hasEpsilonMoves;
    _label = stateLabel;
    _label ??=
        (State<dynamic, dynamic> s) => s.isFinal ? 'V${s.id}' : '${s.id}';
    _sb = StringBuffer();
    _sb.writeln('digraph fa {');
    _visit(state, {});
    _sb.writeln('}');
    return _sb.toString();
  }

  void _visit(S state, Set<S> processed) {
    if (!processed.add(state)) {
      return;
    }

    _sb.write('  state');
    _sb.write(state.id);
    _sb.write(' [label="');
    _sb.write(_label(state));
    _sb.write('"]');
    _sb.writeln(';');
    if (_hasEpsilonMoves) {
      for (final epsilonMove in state.states) {
        _sb.write('  state');
        _sb.write(state.id);
        _sb.write(' -> state');
        _sb.write(epsilonMove.id);
        _sb.write(' [label="');
        _sb.write('ε');
        _sb.write('"]');
        _sb.writeln(';');
        _visit(epsilonMove as S, processed);
      }
    }

    for (final move in state.transitions.groups) {
      final start = move.start;
      final end = move.end;
      final key = move.key;
      final range = start == end
          ? '${_charToString(start)}'
          : '${_charToString(start)}-${_charToString(end)}';
      for (final next in key) {
        _sb.write('  state');
        _sb.write(state.id);
        _sb.write(' -> state');
        _sb.write(next.id);
        _sb.write(' [label="');
        _sb.write(range);
        _sb.write('"]');
        _sb.writeln(';');
        _visit(next as S, processed);
      }
    }
  }

  String _charToString(int c) {
    if (c >= 32 && c <= 127) {
      switch (c) {
        case 92:
          return r'\\';
        case 34:
          return r'\"';
        default:
          return String.fromCharCode(c);
      }
    } else {
      return '0x' + c.toRadixString(16).toUpperCase();
    }
  }
}
