// Generated by 'peg2'
// https://pub.dev/packages/peg2

void main() {
  final text = '''
{"rocket": "🚀 flies to the stars"}
''';

  final parser = ExampleParser();
  final result = parser.parse(text);
  if (!parser.ok) {
    throw parser.error!;
  }

  print(result);
}

class ExampleParser {
  static const int _eof = 1114112;

  FormatException? error;

  int _failStart = -1;

  List _failures = [];

  bool ok = false;

  int _ch = 0;

  int _failPos = -1;

  int _pos = 0;

  String _source = '';

  dynamic parse(String source) {
    _source = source;
    _reset();
    final result = _parseJson();
    if (!ok) {
      _buildError();
    }

    return result;
  }

  dynamic _parseJson() {
    dynamic $0;
    final $2 = _ch;
    final $3 = _pos;
    dynamic $4;
    _parse_leading_spaces();
    final $5 = _parseValue();
    if (ok) {
      _parse_end_of_file();
      if (ok) {
        final v = $5;
        $4 = v;
        $0 = $4;
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  dynamic _parseValue() {
    dynamic $0;
    final $1 = _ch;
    while (true) {
      List? $3;
      final $4 = _parseArray();
      if (ok) {
        $3 = $4;
        $0 = $3;
        break;
      }
      _ch = $1;
      dynamic $6;
      final $7 = _parse_false();
      if (ok) {
        $6 = $7;
        $0 = $6;
        break;
      }
      _ch = $1;
      dynamic $9;
      final $10 = _parse_null();
      if (ok) {
        $9 = $10;
        $0 = $9;
        break;
      }
      _ch = $1;
      dynamic $12;
      final $13 = _parse_true();
      if (ok) {
        $12 = $13;
        $0 = $12;
        break;
      }
      _ch = $1;
      Map<String, dynamic>? $15;
      final $16 = _parseObject();
      if (ok) {
        $15 = $16;
        $0 = $15;
        break;
      }
      _ch = $1;
      num? $18;
      final $19 = _parse_number();
      if (ok) {
        $18 = $19;
        $0 = $18;
        break;
      }
      _ch = $1;
      String? $21;
      final $22 = _parse_string();
      if (ok) {
        $21 = $22;
        $0 = $21;
        break;
      }
      _ch = $1;
      break;
    }
    return $0;
  }

  List? _parseArray() {
    List? $0;
    final $2 = _ch;
    final $3 = _pos;
    List? $4;
    _parse_$LeftSquareBracket();
    if (ok) {
      final $6 = _parseValues();
      final $5 = $6;
      ok = true;
      _parse_$RightSquareBracket();
      if (ok) {
        final v = $5;
        late List $$;
        $$ = v ?? [];
        $4 = $$;
        $0 = $4;
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  List? _parseValues() {
    List? $0;
    final $2 = _ch;
    final $3 = _pos;
    List? $4;
    final $5 = _parseValue();
    if (ok) {
      List? $6;
      final $7 = <dynamic>[];
      while (true) {
        dynamic $8;
        final $10 = _ch;
        final $11 = _pos;
        dynamic $12;
        _parse_$Comma();
        if (ok) {
          final $13 = _parseValue();
          if (ok) {
            final v = $13;
            $12 = v;
            $8 = $12;
          }
        }
        if (!ok) {
          _ch = $10;
          _pos = $11;
        }
        if (!ok) {
          break;
        }
        $7.add($8);
      }
      if (ok = true) {
        $6 = $7;
      }
      final v = $5;
      final n = $6!;
      late List $$;
      $$ = [v, ...n];
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  Map<String, dynamic>? _parseObject() {
    Map<String, dynamic>? $0;
    final $2 = _ch;
    final $3 = _pos;
    Map<String, dynamic>? $4;
    _parse_$LeftBrace();
    if (ok) {
      final $6 = _parseMembers();
      final $5 = $6;
      ok = true;
      _parse_$RightBrace();
      if (ok) {
        final m = $5;
        late Map<String, dynamic> $$;
        $$ = <String, dynamic>{}..addEntries(m ?? []);
        $4 = $$;
        $0 = $4;
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  List<MapEntry<String, dynamic>>? _parseMembers() {
    List<MapEntry<String, dynamic>>? $0;
    final $2 = _ch;
    final $3 = _pos;
    List<MapEntry<String, dynamic>>? $4;
    final $5 = _parseMember();
    if (ok) {
      List<MapEntry<String, dynamic>>? $6;
      final $7 = <MapEntry<String, dynamic>>[];
      while (true) {
        MapEntry<String, dynamic>? $8;
        final $10 = _ch;
        final $11 = _pos;
        MapEntry<String, dynamic>? $12;
        _parse_$Comma();
        if (ok) {
          final $13 = _parseMember();
          if (ok) {
            final m = $13!;
            $12 = m;
            $8 = $12;
          }
        }
        if (!ok) {
          _ch = $10;
          _pos = $11;
        }
        if (!ok) {
          break;
        }
        $7.add($8!);
      }
      if (ok = true) {
        $6 = $7;
      }
      final m = $5!;
      final n = $6!;
      late List<MapEntry<String, dynamic>> $$;
      $$ = [m, ...n];
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  MapEntry<String, dynamic>? _parseMember() {
    MapEntry<String, dynamic>? $0;
    final $2 = _ch;
    final $3 = _pos;
    MapEntry<String, dynamic>? $4;
    final $5 = _parse_string();
    if (ok) {
      _parse_$Colon();
      if (ok) {
        final $6 = _parseValue();
        if (ok) {
          final k = $5!;
          final v = $6;
          late MapEntry<String, dynamic> $$;
          $$ = MapEntry(k, v);
          $4 = $$;
          $0 = $4;
        }
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  dynamic _parse_end_of_file() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    final $2 = _failPos;
    final $3 = _failStart;
    final $4 = _failures;
    _matchAny();
    _ch = $0;
    _pos = $1;
    _failPos = $2;
    _failStart = $3;
    _failures = $4;
    ok = !ok;
    if (!ok) {
      _fail('\'end of file\'');
    }
    return null;
  }

  dynamic _parse_false() {
    _failPos = _pos;
    dynamic $0;
    final $2 = _ch;
    final $3 = _pos;
    dynamic $4;
    _matchString('false');
    if (ok) {
      _parse$$spacing();
      dynamic $$;
      $$ = false;
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
      _fail('\'false\'');
    }
    return $0;
  }

  List<int>? _parse_leading_spaces() {
    _parse$$spacing();

    return null;
  }

  dynamic _parse_null() {
    _failPos = _pos;
    dynamic $0;
    final $2 = _ch;
    final $3 = _pos;
    dynamic $4;
    _matchString('null');
    if (ok) {
      _parse$$spacing();
      dynamic $$;
      $$ = null;
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
      _fail('\'null\'');
    }
    return $0;
  }

  dynamic _parse_true() {
    _failPos = _pos;
    dynamic $0;
    final $2 = _ch;
    final $3 = _pos;
    dynamic $4;
    _matchString('true');
    if (ok) {
      _parse$$spacing();
      dynamic $$;
      $$ = true;
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
      _fail('\'true\'');
    }
    return $0;
  }

  String? _parse_string() {
    _failPos = _pos;
    String? $0;
    final $2 = _ch;
    final $3 = _pos;
    String? $4;
    _matchChar(34, '"');
    if (ok) {
      List<int>? $5;
      final $6 = <int>[];
      while (true) {
        final $7 = _parse$$char();
        if (!ok) {
          break;
        }
        $6.add($7!);
      }
      if (ok = true) {
        $5 = $6;
      }
      _matchChar(34, '"');
      if (ok) {
        _parse$$spacing();
        final c = $5!;
        late String $$;
        $$ = String.fromCharCodes(c);
        $4 = $$;
        $0 = $4;
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
      _fail('\'string\'');
    }
    return $0;
  }

  num? _parse_number() {
    _failPos = _pos;
    num? $0;
    final $2 = _ch;
    final $3 = _pos;
    num? $4;
    String? $5;
    final $6 = _pos;
    final $7 = _ch;
    final $8 = _pos;
    _matchChar(45, 45);
    ok = true;
    final $9 = _ch;
    final $10 = _pos;
    while (true) {
      _matchChar(48, 48);
      if (ok) {
        break;
      }
      _ch = $9;
      _matchRange(49, 57);
      if (ok) {
        while (true) {
          _matchRange(48, 57);
          if (!ok) {
            break;
          }
        }
        ok = true;
      }
      if (ok) {
        break;
      }
      _ch = $9;
      _pos = $10;
      break;
    }
    if (ok) {
      final $11 = _ch;
      final $12 = _pos;
      _matchChar(46, 46);
      if (ok) {
        var $13 = 0;
        while (true) {
          _matchRange(48, 57);
          if (!ok) {
            break;
          }
          $13++;
        }
        ok = $13 != 0;
      }
      if (!ok) {
        _ch = $11;
        _pos = $12;
      }
      ok = true;
      final $14 = _ch;
      final $15 = _pos;
      const $16 = [69, 69, 101, 101];
      _matchRanges($16);
      if (ok) {
        const $17 = [43, 43, 45, 45];
        _matchRanges($17);
        ok = true;
        var $18 = 0;
        while (true) {
          _matchRange(48, 57);
          if (!ok) {
            break;
          }
          $18++;
        }
        ok = $18 != 0;
      }
      if (!ok) {
        _ch = $14;
        _pos = $15;
      }
      ok = true;
    }
    if (!ok) {
      _ch = $7;
      _pos = $8;
    }
    if (ok) {
      $5 = _source.substring($6, _pos);
    }
    if (ok) {
      _parse$$spacing();
      final n = $5!;
      late num $$;
      $$ = num.parse(n);
      $4 = $$;
      $0 = $4;
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
      _fail('\'number\'');
    }
    return $0;
  }

  String? _parse_$LeftBrace() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(123, '{');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\'{\'');
    }
    return null;
  }

  String? _parse_$RightBrace() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(125, '}');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\'}\'');
    }
    return null;
  }

  String? _parse_$LeftSquareBracket() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(91, '[');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\'[\'');
    }
    return null;
  }

  String? _parse_$RightSquareBracket() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(93, ']');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\']\'');
    }
    return null;
  }

  String? _parse_$Comma() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(44, ',');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\',\'');
    }
    return null;
  }

  String? _parse_$Colon() {
    _failPos = _pos;
    final $0 = _ch;
    final $1 = _pos;
    _matchChar(58, ':');
    if (ok) {
      _parse$$spacing();
    }
    if (!ok) {
      _ch = $0;
      _pos = $1;
      _fail('\':\'');
    }
    return null;
  }

  int? _parse$$char() {
    int? $0;
    final $1 = _ch;
    final $2 = _pos;
    while (true) {
      int? $4;
      _matchChar(92, 92);
      if (ok) {
        final $5 = _parse$$escaped();
        if (ok) {
          final r = $5!;
          $4 = r;
          $0 = $4;
          break;
        }
      }
      _ch = $1;
      _pos = $2;
      int? $7;
      final $8 = _parse$$unescaped();
      if (ok) {
        $7 = $8;
        $0 = $7;
        break;
      }
      _ch = $1;
      break;
    }
    return $0;
  }

  int? _parse$$escaped() {
    int? $0;
    final $1 = _ch;
    final $2 = _pos;
    while (true) {
      int? $4;
      final $5 = _matchChar(34, 34);
      if (ok) {
        $4 = $5;
        $0 = $4;
        break;
      }
      _ch = $1;
      int? $7;
      final $8 = _matchChar(92, 92);
      if (ok) {
        $7 = $8;
        $0 = $7;
        break;
      }
      _ch = $1;
      int? $10;
      final $11 = _matchChar(47, 47);
      if (ok) {
        $10 = $11;
        $0 = $10;
        break;
      }
      _ch = $1;
      int? $13;
      _matchChar(98, 98);
      if (ok) {
        late int $$;
        $$ = 0x8;
        $13 = $$;
        $0 = $13;
        break;
      }
      _ch = $1;
      int? $15;
      _matchChar(102, 102);
      if (ok) {
        late int $$;
        $$ = 0xC;
        $15 = $$;
        $0 = $15;
        break;
      }
      _ch = $1;
      int? $17;
      _matchChar(110, 110);
      if (ok) {
        late int $$;
        $$ = 0xA;
        $17 = $$;
        $0 = $17;
        break;
      }
      _ch = $1;
      int? $19;
      _matchChar(114, 114);
      if (ok) {
        late int $$;
        $$ = 0xD;
        $19 = $$;
        $0 = $19;
        break;
      }
      _ch = $1;
      int? $21;
      _matchChar(116, 116);
      if (ok) {
        late int $$;
        $$ = 0x9;
        $21 = $$;
        $0 = $21;
        break;
      }
      _ch = $1;
      int? $23;
      _matchChar(117, 117);
      if (ok) {
        final $24 = _parse$$hexdig4();
        if (ok) {
          final r = $24!;
          $23 = r;
          $0 = $23;
          break;
        }
      }
      _ch = $1;
      _pos = $2;
      break;
    }
    return $0;
  }

  int? _parse$$hexdig4() {
    int? $0;
    final $2 = _ch;
    final $3 = _pos;
    int? $4;
    final $5 = _parse$$hexdig();
    if (ok) {
      final $6 = _parse$$hexdig();
      if (ok) {
        final $7 = _parse$$hexdig();
        if (ok) {
          final $8 = _parse$$hexdig();
          if (ok) {
            final a = $5!;
            final b = $6!;
            final c = $7!;
            final d = $8!;
            late int $$;
            $$ = a * 0xfff + b * 0xff + c * 0xf + d;
            $4 = $$;
            $0 = $4;
          }
        }
      }
    }
    if (!ok) {
      _ch = $2;
      _pos = $3;
    }
    return $0;
  }

  int? _parse$$hexdig() {
    int? $0;
    final $1 = _ch;
    while (true) {
      int? $3;
      final $4 = _matchRange(97, 102);
      if (ok) {
        final v = $4!;
        late int $$;
        $$ = v - 97;
        $3 = $$;
        $0 = $3;
        break;
      }
      _ch = $1;
      int? $6;
      final $7 = _matchRange(65, 70);
      if (ok) {
        final v = $7!;
        late int $$;
        $$ = v - 65;
        $6 = $$;
        $0 = $6;
        break;
      }
      _ch = $1;
      int? $9;
      final $10 = _matchRange(48, 57);
      if (ok) {
        final v = $10!;
        late int $$;
        $$ = v - 48;
        $9 = $$;
        $0 = $9;
        break;
      }
      _ch = $1;
      break;
    }
    return $0;
  }

  int? _parse$$unescaped() {
    int? $0;
    final $1 = _ch;
    while (true) {
      int? $3;
      final $4 = _matchRange(32, 33);
      if (ok) {
        $3 = $4;
        $0 = $3;
        break;
      }
      _ch = $1;
      int? $6;
      final $7 = _matchRange(35, 91);
      if (ok) {
        $6 = $7;
        $0 = $6;
        break;
      }
      _ch = $1;
      int? $9;
      final $10 = _matchRange(93, 1114111);
      if (ok) {
        $9 = $10;
        $0 = $9;
        break;
      }
      _ch = $1;
      break;
    }
    return $0;
  }

  List<int>? _parse$$spacing() {
    while (true) {
      const $0 = [9, 10, 13, 13, 32, 32];
      _matchRanges($0);
      if (!ok) {
        break;
      }
    }
    ok = true;

    return null;
  }

  void _buildError() {
    final names = <String>[];
    final ends = <int>[];
    var failEnd = 0;
    for (var i = 0; i < _failures.length; i += 2) {
      final name = _failures[i] as String;
      final end = _failures[i + 1] as int;
      if (failEnd < end) {
        failEnd = end;
      }

      names.add(name);
      ends.add(end);
    }

    final temp = <String>[];
    for (var i = 0; i < names.length; i++) {
      if (ends[i] == failEnd) {
        temp.add(names[i]);
      }
    }

    final expected = temp.toSet().toList();
    expected.sort();
    final sink = StringBuffer();
    if (_failStart == failEnd) {
      if (failEnd < _source.length) {
        sink.write('Unexpected character ');
        final ch = _getChar(_failStart);
        if (ch >= 32 && ch < 126) {
          sink.write('\'');
          sink.write(String.fromCharCode(ch));
          sink.write('\'');
        } else {
          sink.write('(');
          sink.write(ch);
          sink.write(')');
        }
      } else {
        sink.write('Unexpected end of input');
      }

      if (expected.isNotEmpty) {
        sink.write(', expected: ');
        sink.write(expected.join(', '));
      }
    } else {
      sink.write('Unterminated ');
      if (expected.isEmpty) {
        sink.write('unknown token');
      } else if (expected.length == 1) {
        sink.write('token ');
        sink.write(expected[0]);
      } else {
        sink.write('tokens ');
        sink.write(expected.join(', '));
      }
    }

    error = FormatException(sink.toString(), _source, _failStart);
  }

  void _fail(String name) {
    if (_pos < _failStart) {
      return;
    }

    if (_failStart < _pos) {
      _failStart = _pos;
      _failures = [];
    }

    _failures.add(name);
    _failures.add(_failPos);
  }

  int _getChar(int pos) {
    if (pos < _source.length) {
      var ch = _source.codeUnitAt(pos);
      if (ch >= 0xD800 && ch <= 0xDBFF) {
        if (pos + 1 < _source.length) {
          final ch2 = _source.codeUnitAt(pos + 1);
          if (ch2 >= 0xDC00 && ch2 <= 0xDFFF) {
            ch = ((ch - 0xD800) << 10) + (ch2 - 0xDC00) + 0x10000;
          } else {
            throw FormatException('Unpaired high surrogate', _source, pos);
          }
        } else {
          throw FormatException('The source has been exhausted', _source, pos);
        }
      } else {
        if (ch >= 0xDC00 && ch <= 0xDFFF) {
          throw FormatException(
              'UTF-16 surrogate values are illegal in UTF-32', _source, pos);
        }
      }

      return ch;
    }

    return _eof;
  }

  int? _matchAny() {
    if (_ch == _eof) {
      if (_failPos < _pos) {
        _failPos = _pos;
      }

      ok = false;
      return null;
    }

    final ch = _ch;
    _pos += _ch <= 0xffff ? 1 : 2;
    _ch = _getChar(_pos);
    ok = true;
    return ch;
  }

  T? _matchChar<T>(int ch, T? result) {
    if (ch != _ch) {
      if (_failPos < _pos) {
        _failPos = _pos;
      }

      ok = false;
      return null;
    }

    _pos += _ch <= 0xffff ? 1 : 2;
    _ch = _getChar(_pos);
    ok = true;
    return result;
  }

  int? _matchRange(int start, int end) {
    if (_ch >= start && _ch <= end) {
      final ch = _ch;
      _pos += _ch <= 0xffff ? 1 : 2;
      _ch = _getChar(_pos);
      ok = true;
      return ch;
    }

    if (_failPos < _pos) {
      _failPos = _pos;
    }

    ok = false;
    return null;
  }

  int? _matchRanges(List<int> ranges) {
    // Use binary search
    for (var i = 0; i < ranges.length; i += 2) {
      if (ranges[i] <= _ch) {
        if (ranges[i + 1] >= _ch) {
          final ch = _ch;
          _pos += _ch <= 0xffff ? 1 : 2;
          _ch = _getChar(_pos);
          ok = true;
          return ch;
        }
      } else {
        break;
      }
    }

    ok = false;
    if (_failPos < _pos) {
      _failPos = _pos;
    }

    return null;
  }

  String? _matchString(String text) {
    var i = 0;
    if (_ch == text.codeUnitAt(0)) {
      i++;
      if (_pos + text.length <= _source.length) {
        for (; i < text.length; i++) {
          if (text.codeUnitAt(i) != _source.codeUnitAt(_pos + i)) {
            break;
          }
        }
      }
    }

    ok = i == text.length;
    if (ok) {
      _pos = _pos + text.length;
      _ch = _getChar(_pos);
      return text;
    } else {
      final pos = _pos + i;
      if (_failPos < pos) {
        _failPos = pos;
      }
      return null;
    }
  }

  void _reset() {
    error = null;
    _failPos = 0;
    _failStart = 0;
    _failures = [];
    _pos = 0;
    _ch = _getChar(0);
    ok = false;
  }
}
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: unused_element
