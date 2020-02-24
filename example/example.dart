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

  List<String> _failures;

  int _fcount;

  int _fposEnd;

  int _fposMax;

  int _fposStart;

  List<int> _input;

  List<bool> _memoizable;

  List<List<_Memo>> _memos;

  var _mresult;

  int _pos;

  bool _predicate;

  dynamic _result;

  bool _success;

  String _text;

  List<int> _trackCid;

  List<int> _trackPos;

  dynamic parse(String text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
    _text = text;
    _input = _toRunes(text);
    _reset();
    final result = _parseJson(0, true);
    _buildError();
    _failures = null;
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
        return "'${escape(_input[position])}'";
      }
      return 'end of file';
    }

    final temp = _failures.take(_fcount).toList();
    temp.sort((e1, e2) => e1.compareTo(e2));
    final terminals = temp.toSet();
    final hasMalformed = _fposStart != _fposMax;
    if (terminals.isNotEmpty) {
      if (!hasMalformed) {
        final sb = StringBuffer();
        sb.write('Expected ');
        sb.write(terminals.join(', '));
        sb.write(' but found ');
        sb.write(getc(_fposStart));
        final message = sb.toString();
        error = FormatException(message, _text, _fposStart);
      } else {
        final reason = _fposMax < _input.length ? 'Malformed' : 'Unterminated';
        final sb = StringBuffer();
        sb.write(reason);
        sb.write(' ');
        sb.write(terminals.join(', '));
        final message = sb.toString();
        error = FormatException(message, _text, _fposStart);
      }
    } else {
      final sb = StringBuffer();
      sb.write('Unexpected character ');
      sb.write(getc(_fposStart));
      final message = sb.toString();
      error = FormatException(message, _text, _fposStart);
    }
  }

  void _fail(int start, String name) {
    if (_fposStart < start) {
      _fposStart = start;
      _fposMax = _fposEnd;
      _fcount = 0;
    } else if (_fposMax < _fposEnd) {
      _fposStart = start;
      _fposMax = _fposEnd;
      _fcount = 0;
    }

    if (_fposStart == start && _fposEnd == _fposMax) {
      if (_fcount >= _failures.length) {
        _failures.length += 20;
      }

      _failures[_fcount++] = name;
    }
  }

  int _matchRanges(List<int> ranges) {
    int result;
    _success = false;
    for (var i = 0; i < ranges.length; i += 2) {
      if (ranges[i] <= _c) {
        if (ranges[i + 1] >= _c) {
          result = _c;
          _c = _input[_pos += _c <= 0xffff ? 1 : 2];
          _success = true;
          break;
        }
      } else {
        break;
      }
    }

    if (!_success && _fposEnd < _pos) {
      _fposEnd = _pos;
    }

    return result;
  }

  String _matchString(String text) {
    String result;
    final length = text.length;
    final rest = _text.length - _pos;
    final count = length > rest ? rest : length;
    var pos = _pos;
    var i = 0;
    for (; i < count; i++, pos++) {
      if (text.codeUnitAt(i) != _text.codeUnitAt(pos)) {
        break;
      }
    }

    if (i == length) {
      _c = _input[_pos += length];
      _success = true;
      result = text;
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }

    return result;
  }

  bool _memoized(int id, int cid) {
    final memos = _memos[_pos];
    if (memos != null) {
      for (var i = 0; i < memos.length; i++) {
        final memo = memos[i];
        if (memo.id == id) {
          _pos = memo.pos;
          _mresult = memo.result;
          _success = memo.success;
          _c = _input[_pos];
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

  void _reset() {
    _c = _input[0];
    _failures = [];
    _failures.length = 20;
    _fcount = 0;
    _fposEnd = -1;
    _fposMax = -1;
    _fposStart = -1;
    _memoizable = [];
    _memoizable.length = 187;
    _memos = [];
    _memos.length = _input.length + 1;
    _pos = 0;
    _predicate = false;
    _trackCid = [];
    _trackCid.length = 187;
    _trackPos = [];
    _trackPos.length = 187;
  }

  List<int> _toRunes(String source) {
    final length = source.length;
    final result = List<int>(length + 1);
    for (var pos = 0; pos < length;) {
      int c;
      final start = pos;
      final leading = source.codeUnitAt(pos++);
      if ((leading & 0xFC00) == 0xD800 && pos < length) {
        final trailing = source.codeUnitAt(pos);
        if ((trailing & 0xFC00) == 0xDC00) {
          c = 0x10000 + ((leading & 0x3FF) << 10) + (trailing & 0x3FF);
          pos++;
        } else {
          c = leading;
        }
      } else {
        c = leading;
      }

      result[start] = c;
    }

    result[length] = 0x110000;
    return result;
  }

  dynamic _parseJson(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parse_leading_spaces(3, false);
    _success = true;
    var $8 = _parseValue(4, $1);
    if (_success) {
      var $9 = _parse_end_of_file(5, false);
      if (_success) {
        $4 = $8;
      }
    }
    // NOP;
    if (!_success) {
      _c = $5;
      _pos = $6;
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
    var $6 = _pos;
    var $7 = _parse_$LeftSquareBracket(23, false);
    if (_success) {
      var $8 = _parseValues(25, $1);
      _success = true;
      var $9 = _parse_$RightSquareBracket(26, false);
      if (_success) {
        var v = $8;
        List $$;
        $$ = v ?? [];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
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
    var $6 = _pos;
    var $7 = _parseValue(29, $1);
    if (_success) {
      List $8;
      if ($1) {
        $8 = [];
      }
      for (;;) {
        dynamic $9;
        dynamic $10;
        var $11 = _c;
        var $12 = _pos;
        var $13 = _parse_$Comma(33, false);
        if (_success) {
          var $14 = _parseValue(34, $1);
          if (_success) {
            $10 = $14;
          }
        }
        if (!_success) {
          _c = $11;
          _pos = $12;
        }
        $9 = $10;
        if (!_success) {
          break;
        }
        if ($1) {
          $8.add($9);
        }
      }
      _success = true;
      {
        var v = $7;
        var n = $8;
        List $$;
        $$ = [v, ...n];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
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
    var $6 = _pos;
    var $7 = _parse_$LeftBrace(37, false);
    if (_success) {
      var $8 = _parseMembers(39, $1);
      _success = true;
      var $9 = _parse_$RightBrace(40, false);
      if (_success) {
        var m = $8;
        Map<String, dynamic> $$;
        $$ = <String, dynamic>{}..addEntries(m ?? []);
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
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
    var $6 = _pos;
    var $7 = _parseMember(43, $1);
    if (_success) {
      List<MapEntry<String, dynamic>> $8;
      if ($1) {
        $8 = [];
      }
      for (;;) {
        MapEntry<String, dynamic> $9;
        MapEntry<String, dynamic> $10;
        var $11 = _c;
        var $12 = _pos;
        var $13 = _parse_$Comma(47, false);
        if (_success) {
          var $14 = _parseMember(48, $1);
          if (_success) {
            $10 = $14;
          }
        }
        if (!_success) {
          _c = $11;
          _pos = $12;
        }
        $9 = $10;
        if (!_success) {
          break;
        }
        if ($1) {
          $8.add($9);
        }
      }
      _success = true;
      {
        var m = $7;
        var n = $8;
        List<MapEntry<String, dynamic>> $$;
        $$ = [m, ...n];
        $4 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
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
    var $6 = _pos;
    var $7 = _parse_string(51, $1);
    if (_success) {
      var $8 = _parse_$Colon(52, false);
      if (_success) {
        var $9 = _parseValue(53, $1);
        if (_success) {
          var k = $7;
          var v = $9;
          MapEntry<String, dynamic> $$;
          $$ = MapEntry(k, v);
          $4 = $$;
        }
      }
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  dynamic _parse_end_of_file(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    dynamic $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _predicate;
    var $9 = $1;
    _predicate = true;
    $1 = false;
    int $10;
    _success = _c < _eof;
    if (_success) {
      $10 = _c;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    var $11;
    _success = !_success;
    _c = $6;
    _pos = $7;
    _predicate = $8;
    $1 = $9;
    if (_success) {
      $5 = $11;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'end of file\'');
    }
    return $3;
  }

  dynamic _parse_false(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    dynamic $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    if (_c == 102) {
      $8 = _matchString('false');
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(61, false);
      if (_success) {
        dynamic $$;
        $$ = false;
        $5 = $$;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'false\'');
    }
    return $3;
  }

  List<int> _parse_leading_spaces(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    List<int> $3;
    List<int> $4;
    List<int> $5;
    var $6 = _parse$$spacing(64, false);
    if (_success) {
      $5 = $6;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'leading spaces\'');
    }
    return $3;
  }

  dynamic _parse_null(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    dynamic $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    if (_c == 110) {
      $8 = _matchString('null');
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(68, false);
      if (_success) {
        dynamic $$;
        $$ = null;
        $5 = $$;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'null\'');
    }
    return $3;
  }

  dynamic _parse_true(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    dynamic $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    if (_c == 116) {
      $8 = _matchString('true');
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(72, false);
      if (_success) {
        dynamic $$;
        $$ = true;
        $5 = $$;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'true\'');
    }
    return $3;
  }

  String _parse_string(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 34;
    if (_success) {
      $8 = '\"';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
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
      String $11;
      _success = _c == 34;
      if (_success) {
        $11 = '\"';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        var $12 = _parse$$spacing(79, false);
        if (_success) {
          var c = $9;
          String $$;
          $$ = String.fromCharCodes(c);
          $5 = $$;
        }
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'string\'');
    }
    return $3;
  }

  num _parse_number(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    num $3;
    num $4;
    num $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    var $9 = _pos;
    var $10 = $1;
    $1 = false;
    int $11;
    int $12;
    var $13 = _c;
    var $14 = _pos;
    int $15;
    _success = _c == 45;
    if (_success) {
      $15 = 45;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    _success = true;
    int $16;
    for (;;) {
      int $17;
      int $18;
      _success = _c == 48;
      if (_success) {
        $18 = 48;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $17 = $18;
        $16 = $17;
        break;
      }
      // NOP;
      int $19;
      var $20 = _c;
      var $21 = _pos;
      int $22;
      _success = _c >= 49 && _c <= 57;
      if (_success) {
        $22 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        List<int> $23;
        for (;;) {
          int $24;
          _success = _c >= 48 && _c <= 57;
          if (_success) {
            $24 = _c;
            _c = _input[++_pos];
          } else {
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (!_success) {
            break;
          }
        }
        _success = true;
        $19 = $22;
        // NOP;
      }
      if (!_success) {
        _c = $20;
        _pos = $21;
      } else {
        $16 = $19;
      }
      // NOP;
      break;
    }
    if (_success) {
      int $25;
      int $26;
      var $27 = _c;
      var $28 = _pos;
      int $29;
      _success = _c == 46;
      if (_success) {
        $29 = 46;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        List<int> $30;
        var $31 = false;
        for (;;) {
          int $32;
          _success = _c >= 48 && _c <= 57;
          if (_success) {
            $32 = _c;
            _c = _input[++_pos];
          } else {
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (!_success) {
            _success = $31;
            if (!_success) {
              $30 = null;
            }
            break;
          }
          $31 = true;
        }
        if (_success) {
          $26 = $29;
        }
      }
      if (!_success) {
        _c = $27;
        _pos = $28;
      }
      $25 = $26;
      _success = true;
      int $33;
      int $34;
      var $35 = _c;
      var $36 = _pos;
      int $37;
      _success = _c == 69 || _c == 101;
      if (_success) {
        $37 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        List<int> $38;
        var $39 = false;
        for (;;) {
          int $40;
          if (_c == 32 || _c >= 43 && _c <= 93) {
            _success = true;
            $40 = _c;
            _c = _input[++_pos];
          } else {
            _success = false;
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (!_success) {
            _success = $39;
            if (!_success) {
              $38 = null;
            }
            break;
          }
          $39 = true;
        }
        if (_success) {
          $34 = $37;
        }
      }
      if (!_success) {
        _c = $35;
        _pos = $36;
      }
      $33 = $34;
      _success = true;
      $12 = $15;
      // NOP;
      // NOP;
    }
    // NOP;
    if (!_success) {
      _c = $13;
      _pos = $14;
    }
    $11 = $12;
    if (_success) {
      $8 = _text.substring($9, _pos);
    }
    $1 = $10;
    if (_success) {
      var $41 = _parse$$spacing(106, false);
      if (_success) {
        var n = $8;
        num $$;
        $$ = num.parse(n);
        $5 = $$;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'number\'');
    }
    return $3;
  }

  String _parse_$LeftBrace(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 123;
    if (_success) {
      $8 = '{';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(110, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'{\'');
    }
    return $3;
  }

  String _parse_$RightBrace(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 125;
    if (_success) {
      $8 = '}';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(114, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'}\'');
    }
    return $3;
  }

  String _parse_$LeftSquareBracket(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 91;
    if (_success) {
      $8 = '[';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(118, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'[\'');
    }
    return $3;
  }

  String _parse_$RightSquareBracket(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 93;
    if (_success) {
      $8 = ']';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(122, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\']\'');
    }
    return $3;
  }

  String _parse_$Comma(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 44;
    if (_success) {
      $8 = ',';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(126, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\',\'');
    }
    return $3;
  }

  String _parse_$Colon(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 58;
    if (_success) {
      $8 = ':';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$spacing(130, false);
      if (_success) {
        $5 = $8;
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\':\'');
    }
    return $3;
  }

  int _parse$$digit(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    int $5;
    _success = _c >= 48 && _c <= 57;
    if (_success) {
      $5 = _c;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
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
    int $5;
    _success = _c >= 49 && _c <= 57;
    if (_success) {
      $5 = _c;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
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
      var $6 = _pos;
      int $7;
      _success = _c == 92;
      if (_success) {
        $7 = 92;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        var $8 = _parse$$escaped(140, $1);
        if (_success) {
          $4 = $8;
        }
      }
      if (!_success) {
        _c = $5;
        _pos = $6;
      } else {
        $3 = $4;
        break;
      }
      // NOP;
      int $9;
      var $10 = _parse$$unescaped(142, $1);
      if (_success) {
        $9 = $10;
        $3 = $9;
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
      int $5;
      _success = _c == 34;
      if (_success) {
        $5 = 34;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      int $6;
      int $7;
      _success = _c == 92;
      if (_success) {
        $7 = 92;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $6 = $7;
        $3 = $6;
        break;
      }
      // NOP;
      int $8;
      int $9;
      _success = _c == 47;
      if (_success) {
        $9 = 47;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $8 = $9;
        $3 = $8;
        break;
      }
      // NOP;
      int $10;
      int $11;
      _success = _c == 98;
      if (_success) {
        $11 = 98;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      int $13;
      _success = _c == 102;
      if (_success) {
        $13 = 102;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      int $15;
      _success = _c == 110;
      if (_success) {
        $15 = 110;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      int $17;
      _success = _c == 114;
      if (_success) {
        $17 = 114;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      int $19;
      _success = _c == 116;
      if (_success) {
        $19 = 116;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      var $22 = _pos;
      int $23;
      _success = _c == 117;
      if (_success) {
        $23 = 117;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        var $24 = _parse$$hexdig4(162, $1);
        if (_success) {
          $20 = $24;
        }
      }
      if (!_success) {
        _c = $21;
        _pos = $22;
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
    var $6 = _pos;
    var $7 = _parse$$hexdig(165, $1);
    if (_success) {
      var $8 = _parse$$hexdig(166, $1);
      if (_success) {
        var $9 = _parse$$hexdig(167, $1);
        if (_success) {
          var $10 = _parse$$hexdig(168, $1);
          if (_success) {
            var a = $7;
            var b = $8;
            var c = $9;
            var d = $10;
            int $$;
            $$ = a * 0xfff + b * 0xff + c * 0xf + d;
            $4 = $$;
          }
        }
      }
    }
    if (!_success) {
      _c = $5;
      _pos = $6;
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
      int $5;
      _success = _c >= 97 && _c <= 102;
      if (_success) {
        $5 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $$;
        $$ = $$ - 97;
        $4 = $$;
      }
      if (_success) {
        $3 = $4;
        break;
      }
      int $6;
      int $7;
      _success = _c >= 65 && _c <= 70;
      if (_success) {
        $7 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $$;
        $$ = $$ - 65;
        $6 = $$;
      }
      if (_success) {
        $3 = $6;
        break;
      }
      int $8;
      int $9;
      _success = _c >= 48 && _c <= 57;
      if (_success) {
        $9 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $$;
        $$ = $$ - 48;
        $8 = $$;
      }
      if (_success) {
        $3 = $8;
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
      int $5;
      _success = _c >= 32 && _c <= 33;
      if (_success) {
        $5 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      int $6;
      int $7;
      _success = _c >= 35 && _c <= 91;
      if (_success) {
        $7 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $6 = $7;
        $3 = $6;
        break;
      }
      // NOP;
      int $8;
      int $9;
      _success = _c >= 93 && _c <= 1114111;
      if (_success) {
        $9 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $8 = $9;
        $3 = $8;
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
    for (;;) {
      int $6;
      if (_c >= 9 && _c <= 10 || _c == 13 || _c == 32) {
        _success = true;
        $6 = _c;
        _c = _input[++_pos];
      } else {
        _success = false;
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (!_success) {
        break;
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
