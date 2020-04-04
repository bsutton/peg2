// Generated by 'peg2'
// https://pub.dev/packages/peg2

void main() {
  final parser = ExampleParser();
  final result = parser.parse(_text);
  if (parser.error != null) {
    throw parser.error;
  }

  print(result);
}

final _text = '''
{"rocket": "🚀 flies to the stars"}
''';

class ExampleParser {
  static const _eof = 0x110000;

  FormatException error;

  int _c;

  int _error;

  List<String> _expected;

  int _failure;

  List<int> _input;

  List<List<_Memo>> _memos;

  var _mresult;

  int _pos;

  bool _predicate;

  dynamic _result;

  bool _success;

  String _text;

  dynamic parse(String text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
    _text = text;
    _input = _toRunes(text);
    _reset();
    final result = _parseJson(false, true);
    _buildError();
    _expected = null;
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
          return 'end of file';
      }
      return String.fromCharCode(c);
    }

    String getc(int position) {
      if (position < _text.length) {
        return "'${escape(_input[position])}'";
      }
      return 'end of file';
    }

    String report(String message, String source, int start) {
      if (start < 0 || start > source.length) {
        start = null;
      }

      final sb = StringBuffer();
      sb.write(message);
      var line = 0;
      var col = 0;
      var lineStart = 0;
      var started = false;
      if (start != null) {
        for (var i = 0; i < source.length; i++) {
          final c = source.codeUnitAt(i);
          if (!started) {
            started = true;
            lineStart = i;
            line++;
            col = 1;
          } else {
            col++;
          }
          if (c == 10) {
            started = false;
          }
          if (start == i) {
            break;
          }
        }
      }

      if (start == null) {
        sb.writeln('.');
      } else if (line == 0 || start == source.length) {
        sb.write(' (at offset ');
        sb.write(start);
        sb.writeln('):');
      } else {
        sb.write(' (at line ');
        sb.write(line);
        sb.write(', column ');
        sb.write(col);
        sb.writeln('):');
      }

      List<int> escape(int c) {
        switch (c) {
          case 9:
            return [92, 116];
          case 10:
            return [92, 110];
          case 13:
            return [92, 114];
          default:
            return [c];
        }
      }

      const max = 70;
      if (start != null) {
        final c1 = <int>[];
        final c2 = <int>[];
        final half = max ~/ 2;
        var cr = false;
        for (var i = start; i >= lineStart && c1.length < half; i--) {
          if (i == source.length) {
            c2.insert(0, 94);
          } else {
            final c = source.codeUnitAt(i);
            final escaped = escape(c);
            c1.insertAll(0, escaped);
            if (c == 10) {
              cr = true;
            }

            final r = i == start ? 94 : 32;
            for (var k = 0; k < escaped.length; k++) {
              c2.insert(0, r);
            }
          }
        }

        for (var i = start + 1;
            i < source.length && c1.length < max && !cr;
            i++) {
          final c = source.codeUnitAt(i);
          final escaped = escape(c);
          c1.addAll(escaped);
          if (c == 10) {
            break;
          }
        }

        final text1 = String.fromCharCodes(c1);
        final text2 = String.fromCharCodes(c2);
        sb.writeln(text1);
        sb.writeln(text2);
      }

      return sb.toString();
    }

    final temp = _expected.toList();
    temp.sort((e1, e2) => e1.compareTo(e2));
    final expected = temp.toSet();
    final hasMalformed = false;
    if (expected.isNotEmpty) {
      if (!hasMalformed) {
        final sb = StringBuffer();
        sb.write('Expected ');
        sb.write(expected.join(', '));
        sb.write(' but found ');
        sb.write(getc(_error));
        final title = sb.toString();
        final message = report(title, _text, _error);
        error = FormatException(message);
      } else {
        final reason = _error == _text.length ? 'Unterminated' : 'Malformed';
        final sb = StringBuffer();
        sb.write(reason);
        sb.write(' ');
        sb.write(expected.join(', '));
        final title = sb.toString();
        final message = report(title, _text, _error);
        error = FormatException(message);
      }
    } else {
      final sb = StringBuffer();
      sb.write('Unexpected character ');
      sb.write(getc(_error));
      final title = sb.toString();
      final message = report(title, _text, _error);
      error = FormatException(message);
    }
  }

  void _fail(List<String> expected) {
    if (_error < _failure) {
      _error = _failure;
      _expected = [];
    }
    if (_error == _failure) {
      _expected.addAll(expected);
    }
  }

  int _matchChar(int c) {
    int result;
    if (c == _c) {
      _success = true;
      _c = _input[_pos += _c <= 0xffff ? 1 : 2];
      result = c;
    } else {
      _success = false;
      _failure = _pos;
    }

    return result;
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

    if (!_success) {
      _failure = _pos;
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

    if (_success = i == length) {
      _c = _input[_pos += length];
      result = text;
    } else {
      _failure = _pos + i;
    }

    return result;
  }

  bool _memoized(int id) {
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
    _error = 0;
    _expected = [];
    _failure = -1;
    _memos = [];
    _memos.length = _input.length + 1;
    _pos = 0;
    _predicate = false;
    _success = false;
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

  dynamic _parseJson(bool $0, bool $1) {
    dynamic $2;
    final $3 = _pos;
    final $4 = _c;
    dynamic $6;
    if ($4 >= 9 && $4 <= 10 || $4 == 13 || $4 == 32) {
      _parse_leading_spaces(false, false);
    } else {
      _success = true;
    }
    final $13 = _parseValue(true, $1);
    if (_success) {
      final $14 = _c;
      if ($14 == 1114112) {
        _parse_end_of_file(false, false);
      } else {
        _success = false;
      }
      if (_success) {
        $6 = $13;
      }
    }
    if (!_success) {
      _c = $4;
      _pos = $3;
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const [
        '\'false\'',
        '\'null\'',
        '\'true\'',
        '\'number\'',
        '\'string\'',
        '\'[\'',
        '\'{\''
      ]);
    }
    return $2;
  }

  dynamic _parseValue(bool $0, bool $1) {
    dynamic $2;
    final $3 = _pos;
    if ($0 && _memoized(6)) {
      return _mresult as dynamic;
    }
    final $5 = _pos;
    for (;;) {
      List $6;
      final $9 = _parseArray(false, $1);
      if (_success) {
        $6 = $9;
        $2 = $6;
        break;
      }
      dynamic $10;
      final $11 = _c;
      dynamic $14;
      if ($11 == 102) {
        final $15 = _parse_false(false, $1);
        $14 = $15;
      } else {
        _success = false;
      }
      if (_success) {
        $10 = $14;
        $2 = $10;
        break;
      }
      dynamic $16;
      final $17 = _c;
      dynamic $20;
      if ($17 == 110) {
        final $21 = _parse_null(false, $1);
        $20 = $21;
      } else {
        _success = false;
      }
      if (_success) {
        $16 = $20;
        $2 = $16;
        break;
      }
      dynamic $22;
      final $23 = _c;
      dynamic $26;
      if ($23 == 116) {
        final $27 = _parse_true(false, $1);
        $26 = $27;
      } else {
        _success = false;
      }
      if (_success) {
        $22 = $26;
        $2 = $22;
        break;
      }
      Map<String, dynamic> $28;
      final $31 = _parseObject(false, $1);
      if (_success) {
        $28 = $31;
        $2 = $28;
        break;
      }
      num $32;
      final $33 = _c;
      num $36;
      if ($33 == 45 || $33 >= 48 && $33 <= 57) {
        final $37 = _parse_number(false, $1);
        $36 = $37;
      } else {
        _success = false;
      }
      if (_success) {
        $32 = $36;
        $2 = $32;
        break;
      }
      String $38;
      final $39 = _c;
      String $42;
      if ($39 == 34) {
        final $43 = _parse_string(true, $1);
        $42 = $43;
      } else {
        _success = false;
      }
      if (_success) {
        $38 = $42;
        $2 = $38;
        break;
      }
      break;
    }
    if (!_success && _error == $5) {
      _fail(const [
        '\'false\'',
        '\'null\'',
        '\'true\'',
        '\'number\'',
        '\'string\'',
        '\'[\'',
        '\'{\''
      ]);
    }
    if ($0) {
      _memoize(6, $3, $2);
    }
    return $2;
  }

  List _parseArray(bool $0, bool $1) {
    List $2;
    final $3 = _pos;
    final $4 = _c;
    List $6;
    if ($4 == 91) {
      _parse_$LeftSquareBracket(false, false);
    } else {
      _success = false;
    }
    if (_success) {
      final $12 = _parseValues(false, $1);
      final $13 = $12;
      final $14 = _c;
      if ($14 == 93) {
        _parse_$RightSquareBracket(false, false);
      } else {
        _success = false;
      }
      if (_success) {
        final v = $13;
        List $$;
        $$ = v ?? [];
        $6 = $$;
      }
      if (!_success) {
        _c = $4;
        _pos = $3;
      }
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const ['\'[\'']);
    }
    return $2;
  }

  List _parseValues(bool $0, bool $1) {
    List $2;
    final $3 = _pos;
    List $6;
    final $9 = _parseValue(true, $1);
    if (_success) {
      List $10;
      if ($1) {
        $10 = [];
      }
      for (;;) {
        dynamic $11;
        final $12 = _pos;
        final $13 = _c;
        dynamic $15;
        if ($13 == 44) {
          _parse_$Comma(true, false);
        } else {
          _success = false;
        }
        if (_success) {
          final $21 = _parseValue(false, $1);
          if (_success) {
            $15 = $21;
          } else {
            _c = $13;
            _pos = $12;
          }
        }
        $11 = $15;
        if (!_success && _error == $12) {
          _fail(const ['\',\'']);
        }
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $10.add($11);
        }
      }
      {
        final v = $9;
        final n = $10;
        List $$;
        $$ = [v, ...n];
        $6 = $$;
      }
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const [
        '\'false\'',
        '\'null\'',
        '\'true\'',
        '\'number\'',
        '\'string\'',
        '\'[\'',
        '\'{\''
      ]);
    }
    return $2;
  }

  Map<String, dynamic> _parseObject(bool $0, bool $1) {
    Map<String, dynamic> $2;
    final $3 = _pos;
    final $4 = _c;
    Map<String, dynamic> $6;
    if ($4 == 123) {
      _parse_$LeftBrace(false, false);
    } else {
      _success = false;
    }
    if (_success) {
      final $12 = _parseMembers(false, $1);
      final $13 = $12;
      final $14 = _c;
      if ($14 == 125) {
        _parse_$RightBrace(false, false);
      } else {
        _success = false;
      }
      if (_success) {
        final m = $13;
        Map<String, dynamic> $$;
        $$ = <String, dynamic>{}..addEntries(m ?? []);
        $6 = $$;
      }
      if (!_success) {
        _c = $4;
        _pos = $3;
      }
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const ['\'{\'']);
    }
    return $2;
  }

  List<MapEntry<String, dynamic>> _parseMembers(bool $0, bool $1) {
    List<MapEntry<String, dynamic>> $2;
    final $3 = _pos;
    List<MapEntry<String, dynamic>> $6;
    final $9 = _parseMember(false, $1);
    if (_success) {
      List<MapEntry<String, dynamic>> $10;
      if ($1) {
        $10 = [];
      }
      for (;;) {
        MapEntry<String, dynamic> $11;
        final $12 = _pos;
        final $13 = _c;
        MapEntry<String, dynamic> $15;
        if ($13 == 44) {
          _parse_$Comma(true, false);
        } else {
          _success = false;
        }
        if (_success) {
          final $21 = _parseMember(false, $1);
          if (_success) {
            $15 = $21;
          } else {
            _c = $13;
            _pos = $12;
          }
        }
        $11 = $15;
        if (!_success && _error == $12) {
          _fail(const ['\',\'']);
        }
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $10.add($11);
        }
      }
      {
        final m = $9;
        final n = $10;
        List<MapEntry<String, dynamic>> $$;
        $$ = [m, ...n];
        $6 = $$;
      }
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const ['\'string\'']);
    }
    return $2;
  }

  MapEntry<String, dynamic> _parseMember(bool $0, bool $1) {
    MapEntry<String, dynamic> $2;
    final $3 = _pos;
    final $4 = _c;
    MapEntry<String, dynamic> $6;
    String $10;
    if ($4 == 34) {
      final $11 = _parse_string(true, $1);
      $10 = $11;
    } else {
      _success = false;
    }
    if (_success) {
      final $12 = _c;
      if ($12 == 58) {
        _parse_$Colon(false, false);
      } else {
        _success = false;
      }
      if (_success) {
        final $15 = _parseValue(true, $1);
        if (_success) {
          final k = $10;
          final v = $15;
          MapEntry<String, dynamic> $$;
          $$ = MapEntry(k, v);
          $6 = $$;
        }
      }
      if (!_success) {
        _c = $4;
        _pos = $3;
      }
    }
    $2 = $6;
    if (!_success && _error == $3) {
      _fail(const ['\'string\'']);
    }
    return $2;
  }

  dynamic _parse_end_of_file(bool $0, bool $1) {
    dynamic $2;
    final $3 = _pos;
    final $4 = _c;
    dynamic $7;
    final $12 = _error;
    final $13 = _expected;
    final $14 = _failure;
    final $15 = $1;
    $1 = false;
    if (_c >= 0 && _c <= 1114111) {
      _success = true;
      _c = _input[_pos += _c <= 65535 ? 1 : 2];
    } else {
      _success = false;
      _failure = _pos;
    }
    _success = !_success;
    _c = $4;
    _pos = $3;
    _error = $12;
    _expected = $13;
    _failure = $14;
    $1 = $15;
    var $17;
    if (_success) {
      $7 = $17;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'end of file\'']);
    }
    return $2;
  }

  dynamic _parse_false(bool $0, bool $1) {
    dynamic $2;
    dynamic $7;
    _matchString('false');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      {
        dynamic $$;
        $$ = false;
        $7 = $$;
      }
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'false\'']);
    }
    return $2;
  }

  List<int> _parse_leading_spaces(bool $0, bool $1) {
    List<int> $2;
    final $8 = _c;
    List<int> $11;
    if ($8 >= 9 && $8 <= 10 || $8 == 13 || $8 == 32) {
      final $12 = _parse$$spacing(false, false);
      $11 = $12;
    } else {
      _success = true;
    }
    $2 = $11;
    if (!_success && _error <= _failure) {
      _fail(const ['\'leading spaces\'']);
    }
    return $2;
  }

  dynamic _parse_null(bool $0, bool $1) {
    dynamic $2;
    dynamic $7;
    _matchString('null');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      {
        dynamic $$;
        $$ = null;
        $7 = $$;
      }
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'null\'']);
    }
    return $2;
  }

  dynamic _parse_true(bool $0, bool $1) {
    dynamic $2;
    dynamic $7;
    _matchString('true');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      {
        dynamic $$;
        $$ = true;
        $7 = $$;
      }
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'true\'']);
    }
    return $2;
  }

  String _parse_string(bool $0, bool $1) {
    String $2;
    final $3 = _pos;
    if ($0 && _memoized(73)) {
      return _mresult as String;
    }
    final $4 = _c;
    final $5 = _pos;
    String $7;
    _matchString('\"');
    if (_success) {
      List<int> $11;
      if ($1) {
        $11 = [];
      }
      for (;;) {
        final $12 = _c;
        int $13;
        if ($12 >= 32 && $12 <= 33 || $12 >= 35 && $12 <= 1114111) {
          final $14 = _parse$$char(false, $1);
          $13 = $14;
        } else {
          _success = false;
        }
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $11.add($13);
        }
      }
      _matchString('\"');
      if (_success) {
        final $16 = _c;
        if ($16 >= 9 && $16 <= 10 || $16 == 13 || $16 == 32) {
          _parse$$spacing(false, false);
        } else {
          _success = true;
        }
        {
          final c = $11;
          String $$;
          $$ = String.fromCharCodes(c);
          $7 = $$;
        }
      }
      if (!_success) {
        _c = $4;
        _pos = $5;
      }
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'string\'']);
    }
    if ($0) {
      _memoize(73, $3, $2);
    }
    return $2;
  }

  num _parse_number(bool $0, bool $1) {
    num $2;
    final $3 = _pos;
    num $7;
    String $10;
    final $12 = $1;
    $1 = false;
    final $14 = _pos;
    final $15 = _c;
    _matchChar(45);
    var $27 = _pos;
    for (;;) {
      _matchChar(48);
      if ($27 < _failure) {
        $27 = _failure;
      }
      if (_success) {
        break;
      }
      const $35 = [49, 57];
      _matchRanges($35);
      if (_success) {
        for (;;) {
          const $38 = [48, 57];
          _matchRanges($38);
          if (!_success) {
            _success = true;
            break;
          }
        }
      }
      if ($27 < _failure) {
        $27 = _failure;
      }
      if (_success) {
        break;
      }
      _c = $15;
      _pos = $14;
      _failure = $27;
      break;
    }
    if (_success) {
      final $41 = _pos;
      final $42 = _c;
      _matchChar(46);
      if (_success) {
        var $50 = false;
        for (;;) {
          const $51 = [48, 57];
          _matchRanges($51);
          if (!_success) {
            _success = $50;
            break;
          }
          $50 = true;
        }
        if (!_success) {
          _c = $42;
          _pos = $41;
        }
      }
      final $55 = _pos;
      final $56 = _c;
      const $62 = [69, 69, 101, 101];
      _matchRanges($62);
      if (_success) {
        const $64 = [43, 43, 45, 45];
        _matchRanges($64);
        var $68 = false;
        for (;;) {
          const $69 = [48, 57];
          _matchRanges($69);
          if (!_success) {
            _success = $68;
            break;
          }
          $68 = true;
        }
        if (!_success) {
          _c = $56;
          _pos = $55;
        }
      }
      _success = true;
    }
    if (_success) {
      $10 = _text.substring($3, _pos);
    }
    $1 = $12;
    if (_success) {
      final $72 = _c;
      if ($72 >= 9 && $72 <= 10 || $72 == 13 || $72 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      {
        final n = $10;
        num $$;
        $$ = num.parse(n);
        $7 = $$;
      }
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'number\'']);
    }
    return $2;
  }

  String _parse_$LeftBrace(bool $0, bool $1) {
    String $2;
    String $7;
    final $10 = _matchString('{');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'{\'']);
    }
    return $2;
  }

  String _parse_$RightBrace(bool $0, bool $1) {
    String $2;
    String $7;
    final $10 = _matchString('}');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'}\'']);
    }
    return $2;
  }

  String _parse_$LeftSquareBracket(bool $0, bool $1) {
    String $2;
    String $7;
    final $10 = _matchString('[');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\'[\'']);
    }
    return $2;
  }

  String _parse_$RightSquareBracket(bool $0, bool $1) {
    String $2;
    String $7;
    final $10 = _matchString(']');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\']\'']);
    }
    return $2;
  }

  String _parse_$Comma(bool $0, bool $1) {
    String $2;
    final $3 = _pos;
    if ($0 && _memoized(125)) {
      return _mresult as String;
    }
    String $7;
    final $10 = _matchString(',');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\',\'']);
    }
    if ($0) {
      _memoize(125, $3, $2);
    }
    return $2;
  }

  String _parse_$Colon(bool $0, bool $1) {
    String $2;
    String $7;
    final $10 = _matchString(':');
    if (_success) {
      final $11 = _c;
      if ($11 >= 9 && $11 <= 10 || $11 == 13 || $11 == 32) {
        _parse$$spacing(false, false);
      } else {
        _success = true;
      }
      $7 = $10;
    }
    $2 = $7;
    if (!_success && _error <= _failure) {
      _fail(const ['\':\'']);
    }
    return $2;
  }

  int _parse$$char(bool $0, bool $1) {
    int $2;
    final $3 = _pos;
    final $4 = _c;
    for (;;) {
      int $6;
      final $7 = _c;
      final $8 = _pos;
      _matchChar(92);
      if (_success) {
        final $10 = _c;
        int $11;
        if ($10 == 34 ||
            $10 == 47 ||
            $10 == 92 ||
            $10 == 98 ||
            $10 == 102 ||
            $10 == 110 ||
            $10 == 114 ||
            $10 >= 116 && $10 <= 117) {
          final $12 = _parse$$escaped(false, $1);
          $11 = $12;
        } else {
          _success = false;
        }
        if (_success) {
          $6 = $11;
        } else {
          _c = $7;
          _pos = $8;
        }
      }
      if (_success) {
        $2 = $6;
        break;
      }
      _c = $4;
      _pos = $3;
      int $13;
      final $14 = _c;
      int $17;
      if ($14 >= 32 && $14 <= 33 ||
          $14 >= 35 && $14 <= 91 ||
          $14 >= 93 && $14 <= 1114111) {
        final $18 = _parse$$unescaped(false, $1);
        $17 = $18;
      } else {
        _success = false;
      }
      if (_success) {
        $13 = $17;
        $2 = $13;
        break;
      }
      break;
    }
    return $2;
  }

  int _parse$$escaped(bool $0, bool $1) {
    int $2;
    final $3 = _pos;
    final $4 = _c;
    for (;;) {
      int $6;
      final $9 = _matchChar(34);
      if (_success) {
        $6 = $9;
        $2 = $6;
        break;
      }
      int $10;
      final $13 = _matchChar(92);
      if (_success) {
        $10 = $13;
        $2 = $10;
        break;
      }
      int $14;
      final $17 = _matchChar(47);
      if (_success) {
        $14 = $17;
        $2 = $14;
        break;
      }
      int $18;
      _matchChar(98);
      if (_success) {
        int $$;
        $$ = 0x8;
        $18 = $$;
      }
      if (_success) {
        $2 = $18;
        break;
      }
      int $22;
      _matchChar(102);
      if (_success) {
        int $$;
        $$ = 0xC;
        $22 = $$;
      }
      if (_success) {
        $2 = $22;
        break;
      }
      int $26;
      _matchChar(110);
      if (_success) {
        int $$;
        $$ = 0xA;
        $26 = $$;
      }
      if (_success) {
        $2 = $26;
        break;
      }
      int $30;
      _matchChar(114);
      if (_success) {
        int $$;
        $$ = 0xD;
        $30 = $$;
      }
      if (_success) {
        $2 = $30;
        break;
      }
      int $34;
      _matchChar(116);
      if (_success) {
        int $$;
        $$ = 0x9;
        $34 = $$;
      }
      if (_success) {
        $2 = $34;
        break;
      }
      int $38;
      final $39 = _c;
      final $40 = _pos;
      _matchChar(117);
      if (_success) {
        final $42 = _c;
        int $43;
        if ($42 >= 48 && $42 <= 57 ||
            $42 >= 65 && $42 <= 70 ||
            $42 >= 97 && $42 <= 102) {
          final $44 = _parse$$hexdig4(false, $1);
          $43 = $44;
        } else {
          _success = false;
        }
        if (_success) {
          $38 = $43;
        } else {
          _c = $39;
          _pos = $40;
        }
      }
      if (_success) {
        $2 = $38;
        break;
      }
      _c = $4;
      _pos = $3;
      break;
    }
    return $2;
  }

  int _parse$$hexdig4(bool $0, bool $1) {
    int $2;
    final $3 = _pos;
    final $4 = _c;
    int $6;
    int $10;
    if ($4 >= 48 && $4 <= 57 || $4 >= 65 && $4 <= 70 || $4 >= 97 && $4 <= 102) {
      final $11 = _parse$$hexdig(false, $1);
      $10 = $11;
    } else {
      _success = false;
    }
    if (_success) {
      final $12 = _c;
      int $13;
      if ($12 >= 48 && $12 <= 57 ||
          $12 >= 65 && $12 <= 70 ||
          $12 >= 97 && $12 <= 102) {
        final $14 = _parse$$hexdig(false, $1);
        $13 = $14;
      } else {
        _success = false;
      }
      if (_success) {
        final $15 = _c;
        int $16;
        if ($15 >= 48 && $15 <= 57 ||
            $15 >= 65 && $15 <= 70 ||
            $15 >= 97 && $15 <= 102) {
          final $17 = _parse$$hexdig(false, $1);
          $16 = $17;
        } else {
          _success = false;
        }
        if (_success) {
          final $18 = _c;
          int $19;
          if ($18 >= 48 && $18 <= 57 ||
              $18 >= 65 && $18 <= 70 ||
              $18 >= 97 && $18 <= 102) {
            final $20 = _parse$$hexdig(false, $1);
            $19 = $20;
          } else {
            _success = false;
          }
          if (_success) {
            final a = $10;
            final b = $13;
            final c = $16;
            final d = $19;
            int $$;
            $$ = a * 0xfff + b * 0xff + c * 0xf + d;
            $6 = $$;
          }
        }
      }
      if (!_success) {
        _c = $4;
        _pos = $3;
      }
    }
    $2 = $6;
    return $2;
  }

  int _parse$$hexdig(bool $0, bool $1) {
    int $2;
    for (;;) {
      int $6;
      const $9 = [97, 102];
      _matchRanges($9);
      if (_success) {
        int $$;
        $$ = $$ - 97;
        $6 = $$;
      }
      if (_success) {
        $2 = $6;
        break;
      }
      int $11;
      const $14 = [65, 70];
      _matchRanges($14);
      if (_success) {
        int $$;
        $$ = $$ - 65;
        $11 = $$;
      }
      if (_success) {
        $2 = $11;
        break;
      }
      int $16;
      const $19 = [48, 57];
      _matchRanges($19);
      if (_success) {
        int $$;
        $$ = $$ - 48;
        $16 = $$;
      }
      if (_success) {
        $2 = $16;
        break;
      }
      break;
    }
    return $2;
  }

  int _parse$$unescaped(bool $0, bool $1) {
    int $2;
    for (;;) {
      int $6;
      const $9 = [32, 33];
      final $10 = _matchRanges($9);
      if (_success) {
        $6 = $10;
        $2 = $6;
        break;
      }
      int $11;
      const $14 = [35, 91];
      final $15 = _matchRanges($14);
      if (_success) {
        $11 = $15;
        $2 = $11;
        break;
      }
      int $16;
      const $19 = [93, 1114111];
      final $20 = _matchRanges($19);
      if (_success) {
        $16 = $20;
        $2 = $16;
        break;
      }
      break;
    }
    return $2;
  }

  List<int> _parse$$spacing(bool $0, bool $1) {
    List<int> $2;
    for (;;) {
      const $10 = [9, 10, 13, 13, 32, 32];
      _matchRanges($10);
      if (!_success) {
        _success = true;
        break;
      }
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

// ignore_for_file: unused_element
// ignore_for_file: unused_field
