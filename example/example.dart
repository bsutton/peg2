class JsonParser {
  static const _eof = 0x110000;

  FormatException error;

  int _c;

  int _cp;

  int _failed;

  int _failurePos;

  bool _hasMalformed;

  String _input;

  int _pos;

  bool _predicate;

  dynamic _result;

  bool _success;

  List<String> _terminals;

  int _terminalCount;

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
    return false;
  }

  void _memoize(result) {
    //
  }

  void _reset() {
    _c = _eof;
    _cp = -1;
    _failurePos = -1;
    _hasMalformed = false;
    _pos = 0;
    _predicate = false;
    _terminalCount = 0;
    _terminals = [];
    _terminals.length = 20;
  }

  dynamic _parseJson(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    // NOP;
    var $9 = _parse_leading_spaces(3, false);
    if (!_success) {
      _success = true;
      $9 = null;
    }
    if (_success) {
      var $10 = _parseValue(4, $1);
      if (_success) {
        _parse_end_of_file(5, false);
        if (_success) {
          $4 = $10;
        }
      }
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      $4 = $5;
      if (_success) {
        $3 = $4;
        break;
      }
      dynamic $6;
      var $7 = _parse_false(10, $1);
      $6 = $7;
      if (_success) {
        $3 = $6;
        break;
      }
      dynamic $8;
      var $9 = _parse_null(12, $1);
      $8 = $9;
      if (_success) {
        $3 = $8;
        break;
      }
      dynamic $10;
      var $11 = _parse_true(14, $1);
      $10 = $11;
      if (_success) {
        $3 = $10;
        break;
      }
      Map<String, dynamic> $12;
      var $13 = _parseObject(16, $1);
      $12 = $13;
      if (_success) {
        $3 = $12;
        break;
      }
      num $14;
      var $15 = _parse_number(18, $1);
      $14 = $15;
      if (_success) {
        $3 = $14;
        break;
      }
      String $16;
      var $17 = _parse_string(20, $1);
      $16 = $17;
      if (_success) {
        $3 = $16;
      }
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
      // NOP;
      var $10 = _parseValues(25, $1);
      if (!_success) {
        _success = true;
        $10 = null;
      }
      if (_success) {
        _parse_$RightSquareBracket(26, false);
        if (_success) {
          var v = $10;
          List $$;
          $$ = v ?? [];
          $4 = $$;
        }
      }
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
          } else {
            _c = $12;
            _cp = $13;
            _pos = $14;
          }
        }
        $10 = $11;
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      if (_success) {
        var v = $8;
        var n = $9;
        List $$;
        $$ = [v, ...n];
        $4 = $$;
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      // NOP;
      var $10 = _parseMembers(39, $1);
      if (!_success) {
        _success = true;
        $10 = null;
      }
      if (_success) {
        _parse_$RightBrace(40, false);
        if (_success) {
          var m = $10;
          Map<String, dynamic> $$;
          $$ = <String, dynamic>{}..addEntries(m ?? []);
          $4 = $$;
        }
      }
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
          } else {
            _c = $12;
            _cp = $13;
            _pos = $14;
          }
        }
        $10 = $11;
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      if (_success) {
        var m = $8;
        var n = $9;
        List<MapEntry<String, dynamic>> $$;
        $$ = [m, ...n];
        $4 = $$;
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
    $4 = $11;
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
    $4 = $5;
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
          _success = true;
          break;
        }
        if ($1) {
          $9.add($10);
        }
      }
      if (_success) {
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
      }
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
    // NOP;
    var $17 = _matchChar(45);
    if (!_success) {
      _success = true;
      $17 = null;
    }
    if (_success) {
      int $18;
      for (;;) {
        int $19;
        var $20 = _matchChar(48);
        $19 = $20;
        if (_success) {
          $18 = $19;
          break;
        }
        int $21;
        var $22 = _c;
        var $23 = _cp;
        var $24 = _pos;
        const $25 = [49, 57];
        var $26 = _matchRanges($25);
        if (_success) {
          List<int> $27;
          if ($1) {
            $27 = [];
          }
          for (;;) {
            const $28 = [48, 57];
            var $29 = _matchRanges($28);
            if (!_success) {
              _success = true;
              break;
            }
            if ($1) {
              $27.add($29);
            }
          }
          if (_success) {
            $21 = $26;
          } else {
            _c = $22;
            _cp = $23;
            _pos = $24;
          }
        }
        if (_success) {
          $18 = $21;
        }
        break;
      }
      if (_success) {
        // NOP;
        int $31;
        int $32;
        var $33 = _c;
        var $34 = _cp;
        var $35 = _pos;
        var $36 = _matchChar(46);
        if (_success) {
          List<int> $37;
          if ($1) {
            $37 = [];
          }
          var $38 = false;
          for (;;) {
            const $39 = [48, 57];
            var $40 = _matchRanges($39);
            if (!_success) {
              _success = $38;
              if (!_success) {
                $37 = null;
              }
              break;
            }
            if ($1) {
              $37.add($40);
            }
            $38 = true;
          }
          if (_success) {
            $32 = $36;
          } else {
            _c = $33;
            _cp = $34;
            _pos = $35;
          }
        }
        $31 = $32;
        if (!_success) {
          _success = true;
          $31 = null;
        }
        if (_success) {
          // NOP;
          int $42;
          int $43;
          var $44 = _c;
          var $45 = _cp;
          var $46 = _pos;
          const $47 = [69, 69, 101, 101];
          var $48 = _matchRanges($47);
          if (_success) {
            List<int> $49;
            if ($1) {
              $49 = [];
            }
            var $50 = false;
            for (;;) {
              const $51 = [32, 32, 43, 93];
              var $52 = _matchRanges($51);
              if (!_success) {
                _success = $50;
                if (!_success) {
                  $49 = null;
                }
                break;
              }
              if ($1) {
                $49.add($52);
              }
              $50 = true;
            }
            if (_success) {
              $43 = $48;
            } else {
              _c = $44;
              _cp = $45;
              _pos = $46;
            }
          }
          $42 = $43;
          if (!_success) {
            _success = true;
            $42 = null;
          }
          if (_success) {
            $12 = $17;
          }
        }
      }
      if (!_success) {
        _c = $13;
        _cp = $14;
        _pos = $15;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      } else {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
        } else {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
      int $10;
      var $11 = _parse$$unescaped(142, $1);
      $10 = $11;
      if (_success) {
        $3 = $10;
      }
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
      $4 = $5;
      if (_success) {
        $3 = $4;
        break;
      }
      int $6;
      var $7 = _matchChar(92);
      $6 = $7;
      if (_success) {
        $3 = $6;
        break;
      }
      int $8;
      var $9 = _matchChar(47);
      $8 = $9;
      if (_success) {
        $3 = $8;
        break;
      }
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
        } else {
          _c = $21;
          _cp = $22;
          _pos = $23;
        }
      }
      if (_success) {
        $3 = $20;
      }
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
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
      $4 = $6;
      if (_success) {
        $3 = $4;
        break;
      }
      int $7;
      const $8 = [35, 91];
      var $9 = _matchRanges($8);
      $7 = $9;
      if (_success) {
        $3 = $7;
        break;
      }
      int $10;
      const $11 = [93, 1114111];
      var $12 = _matchRanges($11);
      $10 = $12;
      if (_success) {
        $3 = $10;
      }
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
        _success = true;
        break;
      }
      if ($1) {
        $5.add($7);
      }
    }
    $4 = $5;
    $3 = $4;
    $2 = $3;
    return $2;
  }
}

// ignore_for_file: prefer_final_locals
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_local_variable
