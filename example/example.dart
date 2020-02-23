void main() {
  final parser = ExampleParser();
  final result = parser.parse(_text);
  if (parser.error != null) {
    throw parser.error;
  }

  print(result);
}

final _text = '''
{"foo": false}
''';

class ExampleParser {
  static const _eof = 0x110000;

  FormatException error;

  int _c;

  List<int> _captures;

  int _capturePos;

  int _cp;

  int _failed;

  int _failurePos;

  bool _hasMalformed;

  String _input;

  List<bool> _memoizable;

  List<List<_Memo>> _memos;

  var _mresult;

  int _pos;

  bool _predicate;

  dynamic _result;

  List<_State> _states;

  int _statesPos;

  bool _success;

  List<String> _terminals;

  int _terminalCount;

  List<int> _trackCid;

  List<int> _trackPos;

  dynamic parse(String text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
    _input = text;
    _reset();
    final result = _e0(0, true);
    _buildError();
    _terminals = null;
    _input = null;
    return result;
  }

  void _buildError() {
    if (_success) {
      error = null;
      return;
    }

    String escape(int c) {
      switch (c) {
        case 10:
          return r'\n';
        case 13:
          return r'\r';
        case 09:
          return r'\t';
        case _eof:
          return '';
      }
      return String.fromCharCode(c);
    }

    String getc(int position) {
      if (position < _input.length) {
        return "'${escape(_input.codeUnitAt(position))}'";
      }
      return 'end of file';
    }

    final temp = _terminals.take(_terminalCount).toList();
    temp.sort((e1, e2) => e1.compareTo(e2));
    final terminals = temp.toSet();
    if (terminals.isNotEmpty) {
      if (!_hasMalformed) {
        final sb = StringBuffer();
        sb.write('Expected ');
        sb.write(terminals.join(', '));
        sb.write(' but found ');
        sb.write(getc(_failurePos));
        final message = sb.toString();
        error = FormatException(message, _input, _failurePos);
      } else {
        final reason =
            _failurePos < _input.length ? 'Malformed' : 'Unterminated';
        final sb = StringBuffer();
        sb.write(reason);
        sb.write(' ');
        sb.write(terminals.join(', '));
        final message = sb.toString();
        error = FormatException(message, _input, _failurePos);
      }
    } else {
      final sb = StringBuffer();
      sb.write('Unexpected character ');
      sb.write(getc(_failurePos));
      final message = sb.toString();
      error = FormatException(message, _input, _failurePos);
    }
  }

  void _fail(int failed) {
    if (!_predicate) {
      if (_failurePos < failed) {
        _failurePos = failed;
        _hasMalformed = false;
        _terminalCount = 0;
      }
      if (_failed < failed) {
        _failed = failed;
      }
    }
    _success = false;
  }

  void _failure(String name) {
    var flagged = true;
    final malformed = _failed > _pos;
    if (malformed && !_hasMalformed) {
      _hasMalformed = true;
      _terminalCount = 0;
    } else if (_hasMalformed) {
      flagged = false;
    }
    if (flagged && _failed >= _failurePos) {
      if (_terminals.length <= _terminalCount) {
        _terminals.length += 50;
      }
      _terminals[_terminalCount++] = name;
    }
  }

  void _getch() {
    _cp = _pos;
    var pos = _pos;
    if (pos < _input.length) {
      final leading = _input.codeUnitAt(pos++);
      if ((leading & 0xFC00) == 0xD800 && _pos < _input.length) {
        final trailing = _input.codeUnitAt(pos);
        if ((trailing & 0xFC00) == 0xDC00) {
          _c = 0x10000 + ((leading & 0x3FF) << 10) + (trailing & 0x3FF);
          pos++;
        } else {
          _c = leading;
        }
      } else {
        _c = leading;
      }
    } else {
      _c = _eof;
    }
  }

  int _matchAny() {
    if (_cp != _pos) {
      _getch();
    }
    int result;
    if (_c != _eof) {
      result = _c;
      _pos += _c < 0xffff ? 1 : 2;
      _c = null;
      _success = true;
    } else {
      _fail(_pos);
    }

    return result;
  }

  int _matchChar(int c) {
    if (_cp != _pos) {
      _getch();
    }
    int result;
    if (_c != _eof && _c == c) {
      result = _c;
      _pos += _c < 0xffff ? 1 : 2;
      _c = null;
      _success = true;
    } else {
      _fail(_pos);
    }

    return result;
  }

  int _matchRanges(List<int> ranges) {
    if (_cp != _pos) {
      _getch();
    }
    int result;
    _success = false;
    if (_c != _eof) {
      for (var i = 0; i < ranges.length; i += 2) {
        if (ranges[i] <= _c) {
          if (ranges[i + 1] >= _c) {
            result = _c;
            _pos += _c < 0xffff ? 1 : 2;
            _c = null;
            _success = true;
            break;
          }
        } else {
          break;
        }
      }
    }

    if (!_success) {
      _fail(_pos);
    }

    return result;
  }

  String _matchString(String text) {
    String result;
    final length = text.length;
    final rest = _input.length - _pos;
    final count = length > rest ? rest : length;
    var pos = _pos;
    var i = 0;
    for (; i < count; i++, pos++) {
      if (text.codeUnitAt(i) != _input.codeUnitAt(pos)) {
        break;
      }
    }

    if (i == length) {
      _pos += length;
      _success = true;
      result = text;
    } else {
      _fail(_pos + i);
    }

    return result;
  }

  bool _memoized(int id, int cid) {
    final memos = _memos[_pos];
    if (memos != null) {
      for (var i = 0; i < memos.length; i++) {
        final memo = memos[i];
        if (memo.id == id) {
          _cp = -1;
          _pos = memo.pos;
          _mresult = memo.result;
          _success = memo.success;
          return true;
        }
      }
    }

    if (_memoizable[cid] != null) {
      return false;
    }

    var lastCid = _trackCid[id];
    var lastPos = _trackPos[id];
    _trackCid[id] = cid;
    _trackPos[id] = _pos;
    if (lastCid == null) {
      return false;
    }

    if (lastPos == _pos) {
      if (lastCid != cid) {
        _memoizable[lastCid] = true;
        _memoizable[cid] = false;
      }
    }

    return false;
  }

  void _memoize(int id, int pos, result) {
    var memos = _memos[pos];
    if (memos == null) {
      memos = [];
      _memos[pos] = memos;
    }

    final memo = _Memo(
      id: id,
      pos: _pos,
      result: result,
      success: _success,
    );

    memos.add(memo);
  }

  dynamic _popState() {
    if (_statesPos <= 0) {
      throw StateError('Stack error');
    }

    final state = _states[--_statesPos];
    _c = state.c;
    _cp = state.cp;
    _pos = state.pos;
    _predicate = state.predicate;
    return null;
  }

  void _pushState() {
    if (_statesPos >= _states.length) {
      _states.length += 20;
    }

    final state = _State(c: _c, cp: _cp, pos: _pos, predicate: _predicate);
    _states[_statesPos++] = state;
  }

  void _reset() {
    _c = _eof;
    _captures = [];
    _captures.length = 10;
    _capturePos = 0;
    _cp = -1;
    _failurePos = -1;
    _hasMalformed = false;
    _memoizable = [];
    _memoizable.length = 187;
    _memos = [];
    _memos.length = _input.length + 1;
    _pos = 0;
    _predicate = false;
    _states = [];
    _states.length = 20;
    _statesPos = 0;
    _terminalCount = 0;
    _terminals = [];
    _terminals.length = 20;
    _trackCid = [];
    _trackCid.length = 187;
    _trackPos = [];
    _trackPos.length = 187;
  }

  void _startCapture() {
    if (_capturePos >= _captures.length) {
      _captures.length += 10;
    }

    _captures[_capturePos++] = _pos;
  }

  int _stopCapture() {
    if (_capturePos <= 0) {
      throw StateError('Stack error');
    }

    return _captures[--_capturePos];
  }

  dynamic _e1(List<int> $0, bool $1) {
    dynamic $2;
    if (_success) {
      dynamic $3 = _e6(0, true);
      if (_success) {
        dynamic $4 = _e54(0, true);
        if (_success) {
          $2 = $3;
        }
      }
    }
    return $2;
  }

  dynamic _e0(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      const $3 = [9, 10, 13, 13, 32, 32];
      var $4 = _matchRanges($3);
      var $5 = _e185($4, true);
      _success = true;
      var $6 = _e1($5, true);
      if (_success) {
        $2 = $6;
      }
      break;
    }
    return $2;
  }

  List<int> _e185(int $0, bool $1) {
    List<int> $2;
    List<int> $3;
    if (_success) {
      if ($1) {
        $3 = [];
      }
      for (;;) {
        const $4 = [9, 10, 13, 13, 32, 32];
        var $5 = _matchRanges($4);
        if (!_success) {
          break;
        }
        if ($1) {
          $3.add($5);
        }
        return $2;
      }
    }
    _success = true;
  }

  List _e7(List $0, bool $1) {
    List $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  dynamic _e9(dynamic $0, bool $1) {
    dynamic $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  dynamic _e11(dynamic $0, bool $1) {
    dynamic $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  dynamic _e13(dynamic $0, bool $1) {
    dynamic $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  Map<String, dynamic> _e15(Map<String, dynamic> $0, bool $1) {
    Map<String, dynamic> $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  num _e17(num $0, bool $1) {
    num $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  String _e19(String $0, bool $1) {
    String $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  dynamic _e6(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('[');
      var $4 = _e116($3, true);
      var $5 = _e22($4, true);
      if (_success) {
        $2 = $5;
        break;
      }
      var $6 = _matchString('false');
      var $7 = _e59($6, true);
      if (_success) {
        $2 = $7;
        break;
      }
      var $8 = _matchString('null');
      var $9 = _e66($8, true);
      if (_success) {
        $2 = $9;
        break;
      }
      var $10 = _matchString('true');
      var $11 = _e70($10, true);
      if (_success) {
        $2 = $11;
        break;
      }
      var $12 = _matchString('{');
      var $13 = _e108($12, true);
      var $14 = _e36($13, true);
      if (_success) {
        $2 = $14;
        break;
      }
      _startCapture();
      var $15 = _matchChar(45);
      _success = true;
      var $16 = _e84($15, true);
      var $17 = _e82($16, true);
      var $18 = _e81($17, true);
      if (_success) {
        $2 = $18;
        break;
      }
      var $19 = _matchString('\"');
      var $20 = _e74($19, true);
      if (_success) {
        $2 = $20;
      }
      break;
    }
    return $2;
  }

  String _e116(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  List _e22(String $0, bool $1) {
    List $2;
    if (_success) {
      List $3 = _e27(0, true);
      _success = true;
      String $4 = _e119(0, true);
      if (_success) {
        var v = $3;
        List $$;
        $$ = v ?? [];
        $2 = $$;
      }
      // NOP;
    }
    return $2;
  }

  dynamic _e59(String $0, bool $1) {
    dynamic $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        dynamic $$;
        $$ = false;
        $2 = $$;
      }
    }
    return $2;
  }

  dynamic _e66(String $0, bool $1) {
    dynamic $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        dynamic $$;
        $$ = null;
        $2 = $$;
      }
    }
    return $2;
  }

  dynamic _e70(String $0, bool $1) {
    dynamic $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        dynamic $$;
        $$ = true;
        $2 = $$;
      }
    }
    return $2;
  }

  String _e108(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  Map<String, dynamic> _e36(String $0, bool $1) {
    Map<String, dynamic> $2;
    if (_success) {
      List<MapEntry<String, dynamic>> $3 = _e41(0, true);
      _success = true;
      String $4 = _e111(0, true);
      if (_success) {
        var m = $3;
        Map<String, dynamic> $$;
        $$ = <String, dynamic>{}..addEntries(m ?? []);
        $2 = $$;
      }
      // NOP;
    }
    return $2;
  }

  int _e84(int $0, bool $1) {
    int $2;
    if (_success) {
      var $3 = _e87(0, true);
      if (_success) {
        var $4 = _e95(0, true);
        _success = true;
        var $5 = _e101(0, true);
        _success = true;
        $2 = $0;
        // NOP;
        // NOP;
      }
    }
    return $2;
  }

  int _e88(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e90(int $0, bool $1) {
    int $2;
    if (_success) {
      List<int> $3;
      for (;;) {
        const $4 = [48, 57];
        var $5 = _matchRanges($4);
        if (!_success) {
          break;
        }
      }
      _success = true;
      $2 = $0;
      // NOP;
    }
    return $2;
  }

  int _e87(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchChar(48);
      if (_success) {
        $2 = $3;
        break;
      }
      const $4 = [49, 57];
      var $5 = _matchRanges($4);
      var $6 = _e90($5, true);
      if (_success) {
        $2 = $6;
      }
      break;
    }
    return $2;
  }

  int _e96(int $0, bool $1) {
    int $2;
    if (_success) {
      List<int> $3;
      var $4 = false;
      for (;;) {
        const $5 = [48, 57];
        var $6 = _matchRanges($5);
        if (!_success) {
          _success = $4;
          if (!_success) {
            $3 = null;
          }
          break;
        }
        $4 = true;
      }
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  int _e95(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchChar(46);
      var $4 = _e96($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  int _e102(int $0, bool $1) {
    int $2;
    if (_success) {
      List<int> $3;
      var $4 = false;
      for (;;) {
        const $5 = [32, 32, 43, 93];
        var $6 = _matchRanges($5);
        if (!_success) {
          _success = $4;
          if (!_success) {
            $3 = null;
          }
          break;
        }
        $4 = true;
      }
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  int _e101(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [69, 69, 101, 101];
      var $4 = _matchRanges($3);
      var $5 = _e102($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  String _e82(int $0, bool $1) {
    String $2;
    var $3 = _stopCapture();
    if (_success) {
      $2 = _input.substring($3, _pos);
    }
    return $2;
  }

  num _e81(String $0, bool $1) {
    num $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        var n = $0;
        num $$;
        $$ = num.parse(n);
        $2 = $$;
      }
    }
    return $2;
  }

  String _e74(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3;
      if ($1) {
        $3 = [];
      }
      for (;;) {
        int $4 = _e137(0, true);
        if (!_success) {
          break;
        }
        if ($1) {
          $3.add($4);
        }
      }
      _success = true;
      var $5 = _matchString('\"');
      if (_success) {
        List<int> $6 = _e183(0, true);
        if (_success) {
          var c = $3;
          String $$;
          $$ = String.fromCharCodes(c);
          $2 = $$;
        }
      }
      // NOP;
    }
    return $2;
  }

  List _e21(int $0, bool $1) {
    List $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('[');
      var $4 = _e116($3, true);
      var $5 = _e22($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  List _e28(dynamic $0, bool $1) {
    List $2;
    if (_success) {
      List $3;
      if ($1) {
        $3 = [];
      }
      for (;;) {
        var $4 = _e31(0, true);
        if (!_success) {
          break;
        }
        if ($1) {
          $3.add($4);
        }
      }
      _success = true;
      {
        var v = $0;
        var n = $3;
        List $$;
        $$ = [v, ...n];
        $2 = $$;
      }
      // NOP;
    }
    return $2;
  }

  dynamic _e32(String $0, bool $1) {
    dynamic $2;
    if (_success) {
      dynamic $3 = _e6(0, true);
      if (_success) {
        $2 = $3;
      }
    }
    return $2;
  }

  dynamic _e31(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString(',');
      var $4 = _e124($3, true);
      var $5 = _e32($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  String _e124(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  List _e27(int $0, bool $1) {
    List $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('[');
      var $4 = _e116($3, true);
      var $5 = _e22($4, true);
      var $6 = _e28($5, true);
      if (_success) {
        $2 = $6;
        break;
      }
      var $7 = _matchString('false');
      var $8 = _e59($7, true);
      var $9 = _e28($8, true);
      if (_success) {
        $2 = $9;
        break;
      }
      var $10 = _matchString('null');
      var $11 = _e66($10, true);
      var $12 = _e28($11, true);
      if (_success) {
        $2 = $12;
        break;
      }
      var $13 = _matchString('true');
      var $14 = _e70($13, true);
      var $15 = _e28($14, true);
      if (_success) {
        $2 = $15;
        break;
      }
      var $16 = _matchString('{');
      var $17 = _e108($16, true);
      var $18 = _e36($17, true);
      var $19 = _e28($18, true);
      if (_success) {
        $2 = $19;
        break;
      }
      _startCapture();
      var $20 = _matchChar(45);
      _success = true;
      var $21 = _e84($20, true);
      var $22 = _e82($21, true);
      var $23 = _e81($22, true);
      var $24 = _e28($23, true);
      if (_success) {
        $2 = $24;
        break;
      }
      var $25 = _matchString('\"');
      var $26 = _e74($25, true);
      var $27 = _e28($26, true);
      if (_success) {
        $2 = $27;
      }
      break;
    }
    return $2;
  }

  Map<String, dynamic> _e35(int $0, bool $1) {
    Map<String, dynamic> $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('{');
      var $4 = _e108($3, true);
      var $5 = _e36($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  List<MapEntry<String, dynamic>> _e42(MapEntry<String, dynamic> $0, bool $1) {
    List<MapEntry<String, dynamic>> $2;
    if (_success) {
      List<MapEntry<String, dynamic>> $3;
      if ($1) {
        $3 = [];
      }
      for (;;) {
        var $4 = _e45(0, true);
        if (!_success) {
          break;
        }
        if ($1) {
          $3.add($4);
        }
      }
      _success = true;
      {
        var m = $0;
        var n = $3;
        List<MapEntry<String, dynamic>> $$;
        $$ = [m, ...n];
        $2 = $$;
      }
      // NOP;
    }
    return $2;
  }

  MapEntry<String, dynamic> _e46(String $0, bool $1) {
    MapEntry<String, dynamic> $2;
    if (_success) {
      MapEntry<String, dynamic> $3 = _e49(0, true);
      if (_success) {
        $2 = $3;
      }
    }
    return $2;
  }

  MapEntry<String, dynamic> _e45(int $0, bool $1) {
    MapEntry<String, dynamic> $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString(',');
      var $4 = _e124($3, true);
      var $5 = _e46($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  List<MapEntry<String, dynamic>> _e41(int $0, bool $1) {
    List<MapEntry<String, dynamic>> $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('\"');
      var $4 = _e74($3, true);
      var $5 = _e50($4, true);
      var $6 = _e42($5, true);
      if (_success) {
        $2 = $6;
      }
      break;
    }
    return $2;
  }

  MapEntry<String, dynamic> _e50(String $0, bool $1) {
    MapEntry<String, dynamic> $2;
    if (_success) {
      String $3 = _e127(0, true);
      if (_success) {
        dynamic $4 = _e6(0, true);
        if (_success) {
          var k = $0;
          var v = $4;
          MapEntry<String, dynamic> $$;
          $$ = MapEntry(k, v);
          $2 = $$;
        }
      }
    }
    return $2;
  }

  MapEntry<String, dynamic> _e49(int $0, bool $1) {
    MapEntry<String, dynamic> $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('\"');
      var $4 = _e74($3, true);
      var $5 = _e50($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  dynamic _e55(dynamic $0, bool $1) {
    dynamic $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  dynamic _e54(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      _pushState();
      var $3 = _matchAny();
      var $4 = _popState();
      _success = !_success;
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  dynamic _e58(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('false');
      var $4 = _e59($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  List<int> _e63(List<int> $0, bool $1) {
    List<int> $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  List<int> _e62(int $0, bool $1) {
    List<int> $2;
    _failed = -1;
    for (;;) {
      const $3 = [9, 10, 13, 13, 32, 32];
      var $4 = _matchRanges($3);
      var $5 = _e185($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  dynamic _e65(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('null');
      var $4 = _e66($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  dynamic _e69(int $0, bool $1) {
    dynamic $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('true');
      var $4 = _e70($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e73(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('\"');
      var $4 = _e74($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  num _e80(int $0, bool $1) {
    num $2;
    _failed = -1;
    for (;;) {
      _startCapture();
      var $3 = _matchChar(45);
      _success = true;
      var $4 = _e84($3, true);
      var $5 = _e82($4, true);
      var $6 = _e81($5, true);
      if (_success) {
        $2 = $6;
      }
      break;
    }
    return $2;
  }

  String _e107(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('{');
      var $4 = _e108($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e112(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  String _e111(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('}');
      var $4 = _e112($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e115(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString('[');
      var $4 = _e116($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e120(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  String _e119(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString(']');
      var $4 = _e120($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e123(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString(',');
      var $4 = _e124($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  String _e128(String $0, bool $1) {
    String $2;
    if (_success) {
      List<int> $3 = _e183(0, true);
      if (_success) {
        $2 = $0;
      }
    }
    return $2;
  }

  String _e127(int $0, bool $1) {
    String $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchString(':');
      var $4 = _e128($3, true);
      if (_success) {
        $2 = $4;
      }
      break;
    }
    return $2;
  }

  int _e132(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = $$ - 48;
      $2 = $$;
    }
    return $2;
  }

  int _e131(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [48, 57];
      var $4 = _matchRanges($3);
      var $5 = _e132($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  int _e135(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = $$ - 48;
      $2 = $$;
    }
    return $2;
  }

  int _e134(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [49, 57];
      var $4 = _matchRanges($3);
      var $5 = _e135($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }

  int _e138(int $0, bool $1) {
    int $2;
    if (_success) {
      int $3 = _e143(0, true);
      if (_success) {
        $2 = $3;
      }
    }
    return $2;
  }

  int _e141(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e137(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchChar(92);
      var $4 = _e138($3, true);
      if (_success) {
        $2 = $4;
        break;
      }
      const $5 = [32, 33];
      var $6 = _matchRanges($5);
      if (_success) {
        $2 = $6;
        break;
      }
      const $7 = [35, 91];
      var $8 = _matchRanges($7);
      if (_success) {
        $2 = $8;
        break;
      }
      const $9 = [93, 1114111];
      var $10 = _matchRanges($9);
      if (_success) {
        $2 = $10;
      }
      break;
    }
    return $2;
  }

  int _e144(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e146(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e148(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e150(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = 0x8;
      $2 = $$;
    }
    return $2;
  }

  int _e152(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = 0xC;
      $2 = $$;
    }
    return $2;
  }

  int _e154(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = 0xA;
      $2 = $$;
    }
    return $2;
  }

  int _e156(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = 0xD;
      $2 = $$;
    }
    return $2;
  }

  int _e158(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = 0x9;
      $2 = $$;
    }
    return $2;
  }

  int _e160(int $0, bool $1) {
    int $2;
    if (_success) {
      int $3 = _e163(0, true);
      if (_success) {
        $2 = $3;
      }
    }
    return $2;
  }

  int _e143(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      var $3 = _matchChar(34);
      if (_success) {
        $2 = $3;
        break;
      }
      var $4 = _matchChar(92);
      if (_success) {
        $2 = $4;
        break;
      }
      var $5 = _matchChar(47);
      if (_success) {
        $2 = $5;
        break;
      }
      var $6 = _matchChar(98);
      var $7 = _e150($6, true);
      if (_success) {
        $2 = $7;
        break;
      }
      var $8 = _matchChar(102);
      var $9 = _e152($8, true);
      if (_success) {
        $2 = $9;
        break;
      }
      var $10 = _matchChar(110);
      var $11 = _e154($10, true);
      if (_success) {
        $2 = $11;
        break;
      }
      var $12 = _matchChar(114);
      var $13 = _e156($12, true);
      if (_success) {
        $2 = $13;
        break;
      }
      var $14 = _matchChar(116);
      var $15 = _e158($14, true);
      if (_success) {
        $2 = $15;
        break;
      }
      var $16 = _matchChar(117);
      var $17 = _e160($16, true);
      if (_success) {
        $2 = $17;
      }
      break;
    }
    return $2;
  }

  int _e164(int $0, bool $1) {
    int $2;
    if (_success) {
      int $3 = _e169(0, true);
      if (_success) {
        int $4 = _e169(0, true);
        if (_success) {
          int $5 = _e169(0, true);
          if (_success) {
            var a = $0;
            var b = $3;
            var c = $4;
            var d = $5;
            int $$;
            $$ = a * 0xfff + b * 0xff + c * 0xf + d;
            $2 = $$;
          }
        }
      }
    }
    return $2;
  }

  int _e163(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [97, 102];
      var $4 = _matchRanges($3);
      var $5 = _e170($4, true);
      var $6 = _e164($5, true);
      if (_success) {
        $2 = $6;
        break;
      }
      const $7 = [65, 70];
      var $8 = _matchRanges($7);
      var $9 = _e172($8, true);
      var $10 = _e164($9, true);
      if (_success) {
        $2 = $10;
        break;
      }
      const $11 = [48, 57];
      var $12 = _matchRanges($11);
      var $13 = _e174($12, true);
      var $14 = _e164($13, true);
      if (_success) {
        $2 = $14;
      }
      break;
    }
    return $2;
  }

  int _e170(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = $$ - 97;
      $2 = $$;
    }
    return $2;
  }

  int _e172(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = $$ - 65;
      $2 = $$;
    }
    return $2;
  }

  int _e174(int $0, bool $1) {
    int $2;
    if (_success) {
      int $$;
      $$ = $$ - 48;
      $2 = $$;
    }
    return $2;
  }

  int _e169(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [97, 102];
      var $4 = _matchRanges($3);
      var $5 = _e170($4, true);
      if (_success) {
        $2 = $5;
        break;
      }
      const $6 = [65, 70];
      var $7 = _matchRanges($6);
      var $8 = _e172($7, true);
      if (_success) {
        $2 = $8;
        break;
      }
      const $9 = [48, 57];
      var $10 = _matchRanges($9);
      var $11 = _e174($10, true);
      if (_success) {
        $2 = $11;
      }
      break;
    }
    return $2;
  }

  int _e177(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e179(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e181(int $0, bool $1) {
    int $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  int _e176(int $0, bool $1) {
    int $2;
    _failed = -1;
    for (;;) {
      const $3 = [32, 33];
      var $4 = _matchRanges($3);
      if (_success) {
        $2 = $4;
        break;
      }
      const $5 = [35, 91];
      var $6 = _matchRanges($5);
      if (_success) {
        $2 = $6;
        break;
      }
      const $7 = [93, 1114111];
      var $8 = _matchRanges($7);
      if (_success) {
        $2 = $8;
      }
      break;
    }
    return $2;
  }

  List<int> _e184(List<int> $0, bool $1) {
    List<int> $2;
    if (_success) {
      $2 = $0;
    }
    return $2;
  }

  List<int> _e183(int $0, bool $1) {
    List<int> $2;
    _failed = -1;
    for (;;) {
      const $3 = [9, 10, 13, 13, 32, 32];
      var $4 = _matchRanges($3);
      var $5 = _e185($4, true);
      if (_success) {
        $2 = $5;
      }
      break;
    }
    return $2;
  }
}

class _Memo {
  final int id;

  final int pos;

  final result;

  final bool success;

  _Memo({
    this.id,
    this.pos,
    this.result,
    this.success,
  });
}

class _State {
  final int c;

  final int cp;

  final int pos;

  final bool predicate;

  _State({this.c, this.cp, this.pos, this.predicate});
}
// ignore_for_file: prefer_final_locals
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_local_variable
