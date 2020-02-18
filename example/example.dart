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

  List<int> _states;

  bool _success;

  List<String> _terminals;

  int _terminalCount;

  List<_Buffer<int, int>> _tracks;

  dynamic parse(String text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
    _input = text;
    _reset();
    final result = _parseJson(0, true);
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

    if (_memoizable[cid] == true) {
      return false;
    }

    var track = _tracks[id];
    if (track == null) {
      track = _Buffer(10);
      _tracks[id] = track;
      track.add(cid, _pos);
      return false;
    }

    final key = track.find(_pos);
    if (key == null) {
      return false;
    }

    if (key != cid) {
      _memoizable[key] = true;
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

  void _reset() {
    _c = _eof;
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
    _states.length = 20 * 3;
    _terminalCount = 0;
    _terminals = [];
    _terminals.length = 20;
    _tracks = [];
    _tracks.length = 187;
  }

  dynamic _parseJson(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _parse_leading_spaces(3, false);
    _success = true;
    var $9 = _parseValue(4, $1);
    if (_success) {
      _parse_end_of_file(5, false);
      if (_success) {
        $4 = $9;
      }
    }
    // NOP;
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  dynamic _parseValue(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    for (;;) {
      List $4;
      var $5 = _parseArray(8, $1);
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      dynamic $6;
      var $7 = _parse_false(10, $1);
      if (_success) {
        $6 = $7;
        $3 = $6;
        break;
      }
      // NOP;
      dynamic $8;
      var $9 = _parse_null(12, $1);
      if (_success) {
        $8 = $9;
        $3 = $8;
        break;
      }
      // NOP;
      dynamic $10;
      var $11 = _parse_true(14, $1);
      if (_success) {
        $10 = $11;
        $3 = $10;
        break;
      }
      // NOP;
      Map<String, dynamic> $12;
      var $13 = _parseObject(16, $1);
      if (_success) {
        $12 = $13;
        $3 = $12;
        break;
      }
      // NOP;
      num $14;
      var $15 = _parse_number(18, $1);
      if (_success) {
        $14 = $15;
        $3 = $14;
        break;
      }
      // NOP;
      String $16;
      var $17 = _parse_string(20, $1);
      if (_success) {
        $16 = $17;
        $3 = $16;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  List _parseArray(int $0, bool $1) {
    List $2;
    List $3;
    List $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _parse_$LeftSquareBracket(23, false);
    if (_success) {
      var $9 = _parseValues(25, $1);
      _success = true;
      _parse_$RightSquareBracket(26, false);
      if (_success) {
        var v = $9;
        List $$;
        $$ = v ?? [];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  List _parseValues(int $0, bool $1) {
    List $2;
    List $3;
    List $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseValue(29, $1);
    if (_success) {
      List $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        dynamic $10;
        dynamic $11;
        var $12 = _c;
        var $13 = _cp;
        var $14 = _pos;
        _parse_$Comma(33, false);
        if (_success) {
          var $16 = _parseValue(34, $1);
          if (_success) {
            $11 = $16;
          }
        }
        if (!_success) {
          _c = $12;
          _cp = $13;
          _pos = $14;
        }
        $10 = $11;
        if (!_success) {
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      _success = true;
      {
        var v = $8;
        var n = $9;
        List $$;
        $$ = [v, ...n];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  Map<String, dynamic> _parseObject(int $0, bool $1) {
    Map<String, dynamic> $2;
    Map<String, dynamic> $3;
    Map<String, dynamic> $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _parse_$LeftBrace(37, false);
    if (_success) {
      var $9 = _parseMembers(39, $1);
      _success = true;
      _parse_$RightBrace(40, false);
      if (_success) {
        var m = $9;
        Map<String, dynamic> $$;
        $$ = <String, dynamic>{}..addEntries(m ?? []);
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  List<MapEntry<String, dynamic>> _parseMembers(int $0, bool $1) {
    List<MapEntry<String, dynamic>> $2;
    List<MapEntry<String, dynamic>> $3;
    List<MapEntry<String, dynamic>> $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseMember(43, $1);
    if (_success) {
      List<MapEntry<String, dynamic>> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        MapEntry<String, dynamic> $10;
        MapEntry<String, dynamic> $11;
        var $12 = _c;
        var $13 = _cp;
        var $14 = _pos;
        _parse_$Comma(47, false);
        if (_success) {
          var $16 = _parseMember(48, $1);
          if (_success) {
            $11 = $16;
          }
        }
        if (!_success) {
          _c = $12;
          _cp = $13;
          _pos = $14;
        }
        $10 = $11;
        if (!_success) {
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      _success = true;
      {
        var m = $8;
        var n = $9;
        List<MapEntry<String, dynamic>> $$;
        $$ = [m, ...n];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  MapEntry<String, dynamic> _parseMember(int $0, bool $1) {
    MapEntry<String, dynamic> $2;
    MapEntry<String, dynamic> $3;
    MapEntry<String, dynamic> $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse_string(51, $1);
    if (_success) {
      _parse_$Colon(52, false);
      if (_success) {
        var $10 = _parseValue(53, $1);
        if (_success) {
          var k = $8;
          var v = $10;
          MapEntry<String, dynamic> $$;
          $$ = MapEntry(k, v);
          $4 = $$;
        }
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  dynamic _parse_end_of_file(int $0, bool $1) {
    _failed = -1;
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _predicate;
    var $9 = $1;
    _predicate = true;
    $1 = false;
    _matchAny();
    var $11;
    _success = !_success;
    _c = $5;
    _cp = $6;
    _pos = $7;
    _predicate = $8;
    $1 = $9;
    if (_success) {
      $4 = $11;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'end of file\'');
    }
    return $2;
  }

  dynamic _parse_false(int $0, bool $1) {
    _failed = -1;
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('false');
    if (_success) {
      _parse$$spacing(61, false);
      if (_success) {
        dynamic $$;
        $$ = false;
        $4 = $$;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'false\'');
    }
    return $2;
  }

  List<int> _parse_leading_spaces(int $0, bool $1) {
    _failed = -1;
    List<int> $2;
    List<int> $3;
    List<int> $4;
    var $5 = _parse$$spacing(64, $1);
    if (_success) {
      $4 = $5;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'leading spaces\'');
    }
    return $2;
  }

  dynamic _parse_null(int $0, bool $1) {
    _failed = -1;
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('null');
    if (_success) {
      _parse$$spacing(68, false);
      if (_success) {
        dynamic $$;
        $$ = null;
        $4 = $$;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'null\'');
    }
    return $2;
  }

  dynamic _parse_true(int $0, bool $1) {
    _failed = -1;
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('true');
    if (_success) {
      _parse$$spacing(72, false);
      if (_success) {
        dynamic $$;
        $$ = true;
        $4 = $$;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'true\'');
    }
    return $2;
  }

  String _parse_string(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('\"');
    if (_success) {
      List<int> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        var $10 = _parse$$char(77, $1);
        if (!_success) {
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      _success = true;
      _matchString('\"');
      if (_success) {
        _parse$$spacing(79, false);
        if (_success) {
          var c = $9;
          String $$;
          $$ = String.fromCharCodes(c);
          $4 = $$;
        }
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'string\'');
    }
    return $2;
  }

  num _parse_number(int $0, bool $1) {
    _failed = -1;
    num $2;
    num $3;
    num $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    String $8;
    var $9 = _pos;
    var $10 = $1;
    $1 = false;
    int $11;
    int $12;
    var $13 = _c;
    var $14 = _cp;
    var $15 = _pos;
    var $16 = _matchChar(45);
    _success = true;
    int $17;
    for (;;) {
      int $18;
      var $19 = _matchChar(48);
      if (_success) {
        $18 = $19;
        $17 = $18;
        break;
      }
      // NOP;
      int $20;
      var $21 = _c;
      var $22 = _cp;
      var $23 = _pos;
      const $24 = [49, 57];
      var $25 = _matchRanges($24);
      if (_success) {
        List<int> $26;
        if ($1) {
          $26 = [];
        }
        for (;;) {
          const $27 = [48, 57];
          var $28 = _matchRanges($27);
          if (!_success) {
            break;
          }
          if ($1) {
            $26.add($28);
          }
        }
        _success = true;
        $20 = $25;
        // NOP;
      }
      if (!_success) {
        _c = $21;
        _cp = $22;
        _pos = $23;
      } else {
        $17 = $20;
      }
      // NOP;
      break;
    }
    if (_success) {
      int $29;
      int $30;
      var $31 = _c;
      var $32 = _cp;
      var $33 = _pos;
      var $34 = _matchChar(46);
      if (_success) {
        List<int> $35;
        if ($1) {
          $35 = [];
        }
        var $36 = false;
        for (;;) {
          const $37 = [48, 57];
          var $38 = _matchRanges($37);
          if (!_success) {
            _success = $36;
            if (!_success) {
              $35 = null;
            }
            break;
          }
          if ($1) {
            $35.add($38);
          }
          $36 = true;
        }
        if (_success) {
          $30 = $34;
        }
      }
      if (!_success) {
        _c = $31;
        _cp = $32;
        _pos = $33;
      }
      $29 = $30;
      _success = true;
      int $39;
      int $40;
      var $41 = _c;
      var $42 = _cp;
      var $43 = _pos;
      const $44 = [69, 69, 101, 101];
      var $45 = _matchRanges($44);
      if (_success) {
        List<int> $46;
        if ($1) {
          $46 = [];
        }
        var $47 = false;
        for (;;) {
          const $48 = [32, 32, 43, 93];
          var $49 = _matchRanges($48);
          if (!_success) {
            _success = $47;
            if (!_success) {
              $46 = null;
            }
            break;
          }
          if ($1) {
            $46.add($49);
          }
          $47 = true;
        }
        if (_success) {
          $40 = $45;
        }
      }
      if (!_success) {
        _c = $41;
        _cp = $42;
        _pos = $43;
      }
      $39 = $40;
      _success = true;
      $12 = $16;
      // NOP;
      // NOP;
    }
    // NOP;
    if (!_success) {
      _c = $13;
      _cp = $14;
      _pos = $15;
    }
    $11 = $12;
    if (_success) {
      $8 = _input.substring($9, _pos);
    }
    $1 = $10;
    if (_success) {
      _parse$$spacing(106, false);
      if (_success) {
        var n = $8;
        num $$;
        $$ = num.parse(n);
        $4 = $$;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'number\'');
    }
    return $2;
  }

  String _parse_$LeftBrace(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('{');
    if (_success) {
      _parse$$spacing(110, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'{\'');
    }
    return $2;
  }

  String _parse_$RightBrace(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('}');
    if (_success) {
      _parse$$spacing(114, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'}\'');
    }
    return $2;
  }

  String _parse_$LeftSquareBracket(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('[');
    if (_success) {
      _parse$$spacing(118, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'[\'');
    }
    return $2;
  }

  String _parse_$RightSquareBracket(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString(']');
    if (_success) {
      _parse$$spacing(122, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\']\'');
    }
    return $2;
  }

  String _parse_$Comma(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString(',');
    if (_success) {
      _parse$$spacing(126, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\',\'');
    }
    return $2;
  }

  String _parse_$Colon(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString(':');
    if (_success) {
      _parse$$spacing(130, false);
      if (_success) {
        $4 = $8;
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\':\'');
    }
    return $2;
  }

  int _parse$$digit(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    const $5 = [48, 57];
    _matchRanges($5);
    if (_success) {
      int $$;
      $$ = $$ - 48;
      $4 = $$;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  int _parse$$digit1_9(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    const $5 = [49, 57];
    _matchRanges($5);
    if (_success) {
      int $$;
      $$ = $$ - 48;
      $4 = $$;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  int _parse$$char(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _c;
      var $6 = _cp;
      var $7 = _pos;
      _matchChar(92);
      if (_success) {
        var $9 = _parse$$escaped(140, $1);
        if (_success) {
          $4 = $9;
        }
      }
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      } else {
        $3 = $4;
        break;
      }
      // NOP;
      int $10;
      var $11 = _parse$$unescaped(142, $1);
      if (_success) {
        $10 = $11;
        $3 = $10;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  int _parse$$escaped(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _matchChar(34);
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      int $6;
      var $7 = _matchChar(92);
      if (_success) {
        $6 = $7;
        $3 = $6;
        break;
      }
      // NOP;
      int $8;
      var $9 = _matchChar(47);
      if (_success) {
        $8 = $9;
        $3 = $8;
        break;
      }
      // NOP;
      int $10;
      _matchChar(98);
      if (_success) {
        int $$;
        $$ = 0x8;
        $10 = $$;
      }
      if (_success) {
        $3 = $10;
        break;
      }
      int $12;
      _matchChar(102);
      if (_success) {
        int $$;
        $$ = 0xC;
        $12 = $$;
      }
      if (_success) {
        $3 = $12;
        break;
      }
      int $14;
      _matchChar(110);
      if (_success) {
        int $$;
        $$ = 0xA;
        $14 = $$;
      }
      if (_success) {
        $3 = $14;
        break;
      }
      int $16;
      _matchChar(114);
      if (_success) {
        int $$;
        $$ = 0xD;
        $16 = $$;
      }
      if (_success) {
        $3 = $16;
        break;
      }
      int $18;
      _matchChar(116);
      if (_success) {
        int $$;
        $$ = 0x9;
        $18 = $$;
      }
      if (_success) {
        $3 = $18;
        break;
      }
      int $20;
      var $21 = _c;
      var $22 = _cp;
      var $23 = _pos;
      _matchChar(117);
      if (_success) {
        var $25 = _parse$$hexdig4(162, $1);
        if (_success) {
          $20 = $25;
        }
      }
      if (!_success) {
        _c = $21;
        _cp = $22;
        _pos = $23;
      } else {
        $3 = $20;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  int _parse$$hexdig4(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse$$hexdig(165, $1);
    if (_success) {
      var $9 = _parse$$hexdig(166, $1);
      if (_success) {
        var $10 = _parse$$hexdig(167, $1);
        if (_success) {
          var $11 = _parse$$hexdig(168, $1);
          if (_success) {
            var a = $8;
            var b = $9;
            var c = $10;
            var d = $11;
            int $$;
            $$ = a * 0xfff + b * 0xff + c * 0xf + d;
            $4 = $$;
          }
        }
      }
    }
    if (!_success) {
      _c = $5;
      _cp = $6;
      _pos = $7;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  int _parse$$hexdig(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      const $5 = [97, 102];
      _matchRanges($5);
      if (_success) {
        int $$;
        $$ = $$ - 97;
        $4 = $$;
      }
      if (_success) {
        $3 = $4;
        break;
      }
      int $7;
      const $8 = [65, 70];
      _matchRanges($8);
      if (_success) {
        int $$;
        $$ = $$ - 65;
        $7 = $$;
      }
      if (_success) {
        $3 = $7;
        break;
      }
      int $10;
      const $11 = [48, 57];
      _matchRanges($11);
      if (_success) {
        int $$;
        $$ = $$ - 48;
        $10 = $$;
      }
      if (_success) {
        $3 = $10;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  int _parse$$unescaped(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      const $5 = [32, 33];
      var $6 = _matchRanges($5);
      if (_success) {
        $4 = $6;
        $3 = $4;
        break;
      }
      // NOP;
      int $7;
      const $8 = [35, 91];
      var $9 = _matchRanges($8);
      if (_success) {
        $7 = $9;
        $3 = $7;
        break;
      }
      // NOP;
      int $10;
      const $11 = [93, 1114111];
      var $12 = _matchRanges($11);
      if (_success) {
        $10 = $12;
        $3 = $10;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  List<int> _parse$$spacing(int $0, bool $1) {
    List<int> $2;
    List<int> $3;
    List<int> $4;
    List<int> $5;
    if ($1) {
      $5 = [];
    }
    for (;;) {
      const $6 = [9, 10, 13, 13, 32, 32];
      var $7 = _matchRanges($6);
      if (!_success) {
        break;
      }
      if ($1) {
        $5.add($7);
      }
    }
    _success = true;
    $4 = $5;
    // NOP;
    $3 = $4;
    $2 = $3;
    return $2;
  }
}

class _Buffer<K, V> {
  List<K> keys;

  int length;

  int pos;

  final int size;

  List<V> values;

  _Buffer(this.size) {
    keys = List(size);
    values = List(size);
    length = 0;
    pos = 0;
  }

  void add(K key, V value) {
    keys[pos] = key;
    values[pos] = value;
    if (++pos >= size) {
      pos = 0;
    }

    if (length < size) {
      length++;
    }
  }

  K find(V value) {
    var index = pos - 1;
    var count = length;
    while (count-- > 0) {
      final v = values[index];
      if (v == value) {
        return keys[index];
      }

      if (++index > size) {
        index = 0;
      }
    }

    return null;
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

// ignore_for_file: prefer_final_locals
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_local_variable
