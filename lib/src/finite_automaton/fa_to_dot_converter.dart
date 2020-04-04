part of '../../finite_automaton.dart';

typedef _LabelState<S extends State<dynamic, dynamic>> = String Function(S);

typedef _RangeToString = String Function(int, int);

class FaToDotConverter<S extends State<dynamic, dynamic>> {
  bool _hasEpsilonMoves;

  String Function(S) _labelState;

  String Function(int, int) _rangeToString;

  StringBuffer _sb;

  String convert(S state, bool hasEpsilonMoves,
      {_LabelState<S> labelState, _RangeToString rangeToString}) {
    _hasEpsilonMoves = hasEpsilonMoves;
    _labelState = labelState;
    _labelState ??= _labelState_;
    _rangeToString = rangeToString;
    _rangeToString ??= _rangeToString_;
    _sb = StringBuffer();
    _sb.writeln('digraph fa {');
    _visit(state, {});
    _sb.writeln('}');
    return _sb.toString();
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

  String _labelState_(State<dynamic, dynamic> s) {
    return s.isFinal ? 'V${s.id}' : '${s.id}';
  }

  String _rangeToString_(int start, int end) {
    return start == end
        ? '${_charToString(start)}'
        : '${_charToString(start)}-${_charToString(end)}';
  }

  void _visit(S state, Set<S> processed) {
    if (!processed.add(state)) {
      return;
    }

    _sb.write('  state');
    _sb.write(state.id);
    _sb.write(' [label="');
    _sb.write(_labelState(state));
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
      final range = _rangeToString(start, end);
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
}
