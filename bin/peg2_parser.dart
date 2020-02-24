import 'package:peg2/grammar.dart';
import 'package:peg2/expressions.dart';

int _escape(int c) {
  switch (c) {
    case 110:
      return 0xA;
    case 114:
      return 0xD;
    case 116:
      return 0x9;
  }

  return c;
}

Expression _prefix(String prefix, Expression expression, String variable) {
  switch (prefix) {
    case '&':
      expression = AndPredicateExpression(expression);
      break;
    case '!':
      expression = NotPredicateExpression(expression);
      break;
  }

  expression.variable = variable;
  return expression;
}

Expression _suffix(String suffix, Expression expression) {
  switch (suffix) {
    case '?':
      return OptionalExpression(expression);
    case '*':
      return ZeroOrMoreExpression(expression);
    case '+':
      return OneOrMoreExpression(expression);
  }

  return expression;
}

class Peg2Parser {
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
    final result = _parseGrammar(0, true);
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
    _memoizable.length = 444;
    _memos = [];
    _memos.length = _input.length + 1;
    _pos = 0;
    _predicate = false;
    _trackCid = [];
    _trackCid.length = 444;
    _trackPos = [];
    _trackPos.length = 444;
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

  Grammar _parseGrammar(int $0, bool $1) {
    Grammar $2;
    Grammar $3;
    Grammar $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parse_leading_spaces(3, false);
    _success = true;
    var $8 = _parse_globals(5, $1);
    _success = true;
    var $9 = _parse_members(7, $1);
    _success = true;
    List<ProductionRule> $10;
    if ($1) {
      $10 = [];
    }
    var $11 = false;
    for (;;) {
      var $12 = _parseDefinition(9, $1);
      if (!_success) {
        _success = $11;
        if (!_success) {
          $10 = null;
        }
        break;
      }
      if ($1) {
        $10.add($12);
      }
      $11 = true;
    }
    if (_success) {
      var $13 = _parse_end_of_file(10, false);
      if (_success) {
        var g = $8;
        var m = $9;
        var d = $10;
        Grammar $$;
        $$ = Grammar(d, g, m);
        $4 = $$;
      }
    }
    // NOP;
    // NOP;
    // NOP;
    if (!_success) {
      _c = $5;
      _pos = $6;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  ProductionRule _parseDefinition(int $0, bool $1) {
    ProductionRule $2;
    ProductionRule $3;
    for (;;) {
      ProductionRule $4;
      var $5 = _parseNonterminalDefinition(13, $1);
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      ProductionRule $6;
      var $7 = _parseTerminalDefinition(15, $1);
      if (_success) {
        $6 = $7;
        $3 = $6;
        break;
      }
      // NOP;
      ProductionRule $8;
      var $9 = _parseSubterminalDefinition(17, $1);
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

  ProductionRule _parseNonterminalDefinition(int $0, bool $1) {
    ProductionRule $2;
    ProductionRule $3;
    for (;;) {
      ProductionRule $4;
      var $5 = _c;
      var $6 = _pos;
      var $7 = _parseType(20, $1);
      if (_success) {
        var $8 = _parse_non_terminal_name(21, $1);
        if (_success) {
          var $9 = _parse_$EqualSign(22, false);
          if (_success) {
            var $10 = _parseNonterminalExpression(23, $1);
            if (_success) {
              var $11 = _parse_$Semicolon(24, false);
              if (_success) {
                var t = $7;
                var n = $8;
                var e = $10;
                ProductionRule $$;
                $$ = ProductionRule(n, ProductionRuleKind.Nonterminal, e, t);
                $4 = $$;
              }
            }
          }
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
      ProductionRule $12;
      var $13 = _c;
      var $14 = _pos;
      var $15 = _parse_non_terminal_name(26, $1);
      if (_success) {
        var $16 = _parse_$EqualSign(27, false);
        if (_success) {
          var $17 = _parseNonterminalExpression(28, $1);
          if (_success) {
            var $18 = _parse_$Semicolon(29, false);
            if (_success) {
              var n = $15;
              var e = $17;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Nonterminal, e, null);
              $12 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $13;
        _pos = $14;
      } else {
        $3 = $12;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  OrderedChoiceExpression _parseNonterminalExpression(int $0, bool $1) {
    if (_memoized(30, $0)) {
      return _mresult as OrderedChoiceExpression;
    }
    var $2 = _pos;
    OrderedChoiceExpression $3;
    OrderedChoiceExpression $4;
    OrderedChoiceExpression $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _parseNonterminalSequence(32, $1);
    if (_success) {
      List<SequenceExpression> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        SequenceExpression $10;
        SequenceExpression $11;
        var $12 = _c;
        var $13 = _pos;
        var $14 = _parse_$Slash(36, false);
        if (_success) {
          var $15 = _parseNonterminalSequence(37, $1);
          if (_success) {
            $11 = $15;
          }
        }
        if (!_success) {
          _c = $12;
          _pos = $13;
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
        var e = $8;
        var n = $9;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(30, $2, $3);
    }
    return $3;
  }

  SequenceExpression _parseNonterminalSequence(int $0, bool $1) {
    if (_memoized(38, $0)) {
      return _mresult as SequenceExpression;
    }
    var $2 = _pos;
    SequenceExpression $3;
    SequenceExpression $4;
    SequenceExpression $5;
    var $6 = _c;
    var $7 = _pos;
    List<Expression> $8;
    if ($1) {
      $8 = [];
    }
    var $9 = false;
    for (;;) {
      var $10 = _parseNonterminalPrefix(41, $1);
      if (!_success) {
        _success = $9;
        if (!_success) {
          $8 = null;
        }
        break;
      }
      if ($1) {
        $8.add($10);
      }
      $9 = true;
    }
    if (_success) {
      var $11 = _parse_action(43, $1);
      _success = true;
      {
        var e = $8;
        var a = $11;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(38, $2, $3);
    }
    return $3;
  }

  Expression _parseNonterminalPrefix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parse_semantic_value(47, $1);
    _success = true;
    String $8;
    for (;;) {
      String $9;
      var $10 = _parse_$Ampersand(51, $1);
      if (_success) {
        $9 = $10;
        $8 = $9;
        break;
      }
      // NOP;
      String $11;
      var $12 = _parse_$ExclamationMark(53, $1);
      if (_success) {
        $11 = $12;
        $8 = $11;
      }
      // NOP;
      break;
    }
    _success = true;
    var $13 = _parseNonterminalSuffix(54, $1);
    if (_success) {
      var s = $7;
      var p = $8;
      var e = $13;
      Expression $$;
      $$ = _prefix(p, e, s);
      $4 = $$;
    }
    // NOP;
    // NOP;
    if (!_success) {
      _c = $5;
      _pos = $6;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  Expression _parseNonterminalSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parseNonterminalPrimary(57, $1);
    if (_success) {
      String $8;
      for (;;) {
        String $9;
        var $10 = _parse_$QuestionMark(61, $1);
        if (_success) {
          $9 = $10;
          $8 = $9;
          break;
        }
        // NOP;
        String $11;
        var $12 = _parse_$Asterisk(63, $1);
        if (_success) {
          $11 = $12;
          $8 = $11;
          break;
        }
        // NOP;
        String $13;
        var $14 = _parse_$PlusSign(65, $1);
        if (_success) {
          $13 = $14;
          $8 = $13;
        }
        // NOP;
        break;
      }
      _success = true;
      {
        var e = $7;
        var s = $8;
        Expression $$;
        $$ = _suffix(s, e);
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

  Expression _parseNonterminalPrimary(int $0, bool $1) {
    Expression $2;
    Expression $3;
    for (;;) {
      Expression $4;
      var $5 = _parse_non_terminal_name(68, $1);
      if (_success) {
        var n = $5;
        Expression $$;
        $$ = NonterminalExpression(n);
        $4 = $$;
      }
      if (_success) {
        $3 = $4;
        break;
      }
      Expression $6;
      var $7 = _parse_terminal_name(70, $1);
      if (_success) {
        var n = $7;
        Expression $$;
        $$ = TerminalExpression(n);
        $6 = $$;
      }
      if (_success) {
        $3 = $6;
        break;
      }
      Expression $8;
      var $9 = _c;
      var $10 = _pos;
      var $11 = _parse_$LeftParenthesis(72, false);
      if (_success) {
        var $12 = _parseNonterminalExpression(73, $1);
        if (_success) {
          var $13 = _parse_$RightParenthesis(74, false);
          if (_success) {
            $8 = $12;
          }
        }
      }
      if (!_success) {
        _c = $9;
        _pos = $10;
      } else {
        $3 = $8;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  ProductionRule _parseTerminalDefinition(int $0, bool $1) {
    ProductionRule $2;
    ProductionRule $3;
    for (;;) {
      ProductionRule $4;
      var $5 = _c;
      var $6 = _pos;
      var $7 = _parseType(77, $1);
      if (_success) {
        var $8 = _parse_terminal_name(78, $1);
        if (_success) {
          var $9 = _parse_$EqualSign(79, false);
          if (_success) {
            var $10 = _parseExpression(80, $1);
            if (_success) {
              var $11 = _parse_$Semicolon(81, false);
              if (_success) {
                var t = $7;
                var n = $8;
                var e = $10;
                ProductionRule $$;
                $$ = ProductionRule(n, ProductionRuleKind.Terminal, e, t);
                $4 = $$;
              }
            }
          }
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
      ProductionRule $12;
      var $13 = _c;
      var $14 = _pos;
      var $15 = _parse_terminal_name(83, $1);
      if (_success) {
        var $16 = _parse_$EqualSign(84, false);
        if (_success) {
          var $17 = _parseExpression(85, $1);
          if (_success) {
            var $18 = _parse_$Semicolon(86, false);
            if (_success) {
              var n = $15;
              var e = $17;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Terminal, e, null);
              $12 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $13;
        _pos = $14;
      } else {
        $3 = $12;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  OrderedChoiceExpression _parseExpression(int $0, bool $1) {
    if (_memoized(87, $0)) {
      return _mresult as OrderedChoiceExpression;
    }
    var $2 = _pos;
    OrderedChoiceExpression $3;
    OrderedChoiceExpression $4;
    OrderedChoiceExpression $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _parseSequence(89, $1);
    if (_success) {
      List<SequenceExpression> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        SequenceExpression $10;
        SequenceExpression $11;
        var $12 = _c;
        var $13 = _pos;
        var $14 = _parse_$Slash(93, false);
        if (_success) {
          var $15 = _parseSequence(94, $1);
          if (_success) {
            $11 = $15;
          }
        }
        if (!_success) {
          _c = $12;
          _pos = $13;
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
        var e = $8;
        var n = $9;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(87, $2, $3);
    }
    return $3;
  }

  SequenceExpression _parseSequence(int $0, bool $1) {
    if (_memoized(95, $0)) {
      return _mresult as SequenceExpression;
    }
    var $2 = _pos;
    SequenceExpression $3;
    SequenceExpression $4;
    SequenceExpression $5;
    var $6 = _c;
    var $7 = _pos;
    List<Expression> $8;
    if ($1) {
      $8 = [];
    }
    var $9 = false;
    for (;;) {
      var $10 = _parsePrefix(98, $1);
      if (!_success) {
        _success = $9;
        if (!_success) {
          $8 = null;
        }
        break;
      }
      if ($1) {
        $8.add($10);
      }
      $9 = true;
    }
    if (_success) {
      var $11 = _parse_action(100, $1);
      _success = true;
      {
        var e = $8;
        var a = $11;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(95, $2, $3);
    }
    return $3;
  }

  Expression _parsePrefix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parse_semantic_value(104, $1);
    _success = true;
    String $8;
    for (;;) {
      String $9;
      var $10 = _parse_$Ampersand(108, $1);
      if (_success) {
        $9 = $10;
        $8 = $9;
        break;
      }
      // NOP;
      String $11;
      var $12 = _parse_$ExclamationMark(110, $1);
      if (_success) {
        $11 = $12;
        $8 = $11;
      }
      // NOP;
      break;
    }
    _success = true;
    var $13 = _parseSuffix(111, $1);
    if (_success) {
      var s = $7;
      var p = $8;
      var e = $13;
      Expression $$;
      $$ = _prefix(p, e, s);
      $4 = $$;
    }
    // NOP;
    // NOP;
    if (!_success) {
      _c = $5;
      _pos = $6;
    }
    $3 = $4;
    $2 = $3;
    return $2;
  }

  Expression _parseSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parsePrimary(114, $1);
    if (_success) {
      String $8;
      for (;;) {
        String $9;
        var $10 = _parse_$QuestionMark(118, $1);
        if (_success) {
          $9 = $10;
          $8 = $9;
          break;
        }
        // NOP;
        String $11;
        var $12 = _parse_$Asterisk(120, $1);
        if (_success) {
          $11 = $12;
          $8 = $11;
          break;
        }
        // NOP;
        String $13;
        var $14 = _parse_$PlusSign(122, $1);
        if (_success) {
          $13 = $14;
          $8 = $13;
        }
        // NOP;
        break;
      }
      _success = true;
      {
        var e = $7;
        var s = $8;
        Expression $$;
        $$ = _suffix(s, e);
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

  Expression _parsePrimary(int $0, bool $1) {
    Expression $2;
    Expression $3;
    for (;;) {
      Expression $4;
      var $5 = _parse_sub_terminal_name(125, $1);
      if (_success) {
        var n = $5;
        Expression $$;
        $$ = SubterminalExpression(n);
        $4 = $$;
      }
      if (_success) {
        $3 = $4;
        break;
      }
      Expression $6;
      var $7 = _c;
      var $8 = _pos;
      var $9 = _parse_$LeftParenthesis(127, false);
      if (_success) {
        var $10 = _parseExpression(128, $1);
        if (_success) {
          var $11 = _parse_$RightParenthesis(129, false);
          if (_success) {
            $6 = $10;
          }
        }
      }
      if (!_success) {
        _c = $7;
        _pos = $8;
      } else {
        $3 = $6;
        break;
      }
      // NOP;
      Expression $12;
      var $13 = _parse_literal(131, $1);
      if (_success) {
        $12 = $13;
        $3 = $12;
        break;
      }
      // NOP;
      Expression $14;
      var $15 = _parse_character_class(133, $1);
      if (_success) {
        $14 = $15;
        $3 = $14;
        break;
      }
      // NOP;
      Expression $16;
      var $17 = _parse_$Period(135, $1);
      if (_success) {
        Expression $$;
        $$ = AnyCharacterExpression();
        $16 = $$;
      }
      if (_success) {
        $3 = $16;
        break;
      }
      Expression $18;
      var $19 = _c;
      var $20 = _pos;
      var $21 = _parse_$LessThanSign(137, false);
      if (_success) {
        var $22 = _parseExpression(138, $1);
        if (_success) {
          var $23 = _parse_$GreaterThanSign(139, false);
          if (_success) {
            var e = $22;
            Expression $$;
            $$ = CaptureExpression(e);
            $18 = $$;
          }
        }
      }
      if (!_success) {
        _c = $19;
        _pos = $20;
      } else {
        $3 = $18;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  ProductionRule _parseSubterminalDefinition(int $0, bool $1) {
    ProductionRule $2;
    ProductionRule $3;
    for (;;) {
      ProductionRule $4;
      var $5 = _c;
      var $6 = _pos;
      var $7 = _parseType(142, $1);
      if (_success) {
        var $8 = _parse_sub_terminal_name(143, $1);
        if (_success) {
          var $9 = _parse_$EqualSign(144, false);
          if (_success) {
            var $10 = _parseExpression(145, $1);
            if (_success) {
              var $11 = _parse_$Semicolon(146, false);
              if (_success) {
                var t = $7;
                var n = $8;
                var e = $10;
                ProductionRule $$;
                $$ = ProductionRule(n, ProductionRuleKind.Subterminal, e, t);
                $4 = $$;
              }
            }
          }
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
      ProductionRule $12;
      var $13 = _c;
      var $14 = _pos;
      var $15 = _parse_sub_terminal_name(148, $1);
      if (_success) {
        var $16 = _parse_$EqualSign(149, false);
        if (_success) {
          var $17 = _parseExpression(150, $1);
          if (_success) {
            var $18 = _parse_$Semicolon(151, false);
            if (_success) {
              var n = $15;
              var e = $17;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Subterminal, e, null);
              $12 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $13;
        _pos = $14;
      } else {
        $3 = $12;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  String _parseType(int $0, bool $1) {
    if (_memoized(152, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _parseTypeName(154, $1);
    if (_success) {
      List<String> $9;
      List<String> $10;
      var $11 = _c;
      var $12 = _pos;
      var $13 = _parse_$LessThanSign(158, false);
      if (_success) {
        var $14 = _parseTypeArguments(159, $1);
        if (_success) {
          var $15 = _parse_$GreaterThanSign(160, false);
          if (_success) {
            $10 = $14;
          }
        }
      }
      if (!_success) {
        _c = $11;
        _pos = $12;
      }
      $9 = $10;
      _success = true;
      {
        var n = $8;
        var a = $9;
        String $$;
        $$ = n + (a == null ? '' : '<' + a.join(', ') + '>');
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(152, $2, $3);
    }
    return $3;
  }

  String _parseTypeName(int $0, bool $1) {
    String $2;
    String $3;
    for (;;) {
      String $4;
      var $5 = _c;
      var $6 = _pos;
      var $7 = _parse_library_prefix(163, $1);
      if (_success) {
        var $8 = _parse_$Period(164, false);
        if (_success) {
          var $9 = _parse_type_name(165, $1);
          if (_success) {
            var p = $7;
            var n = $9;
            String $$;
            $$ = '$p.$n';
            $4 = $$;
          }
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
      String $10;
      var $11 = _parse_type_name(167, $1);
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

  List<String> _parseTypeArguments(int $0, bool $1) {
    List<String> $2;
    List<String> $3;
    List<String> $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _parseType(170, $1);
    if (_success) {
      List<String> $8;
      if ($1) {
        $8 = [];
      }
      for (;;) {
        String $9;
        String $10;
        var $11 = _c;
        var $12 = _pos;
        var $13 = _parse_$Comma(174, false);
        if (_success) {
          var $14 = _parseType(175, $1);
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
        var t = $7;
        var n = $8;
        List<String> $$;
        $$ = [t, ...n];
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

  String _parse_non_terminal_name(int $0, bool $1) {
    if (_memoized(176, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _parse$$IDENTIFIER(178, $1);
    if (_success) {
      var $9 = _parse$$SPACING(179, false);
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
      _fail($2, '\'non terminal name\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(176, $2, $3);
    }
    return $3;
  }

  String _parse_terminal_name(int $0, bool $1) {
    if (_memoized(180, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
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
    _success = _c == 39;
    if (_success) {
      $15 = 39;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      List $16;
      var $17 = false;
      for (;;) {
        dynamic $18;
        dynamic $19;
        var $20 = _c;
        var $21 = _pos;
        var $22 = _c;
        var $23 = _pos;
        var $24 = _predicate;
        var $25 = $1;
        _predicate = true;
        $1 = false;
        int $26;
        _success = _c == 39;
        if (_success) {
          $26 = 39;
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        var $27;
        _success = !_success;
        _c = $22;
        _pos = $23;
        _predicate = $24;
        $1 = $25;
        if (_success) {
          var $28 = _parse$$TERMINAL_CHAR(191, false);
          if (_success) {
            $19 = $27;
          }
        }
        if (!_success) {
          _c = $20;
          _pos = $21;
        }
        $18 = $19;
        if (!_success) {
          _success = $17;
          if (!_success) {
            $16 = null;
          }
          break;
        }
        $17 = true;
      }
      if (_success) {
        int $29;
        _success = _c == 39;
        if (_success) {
          $29 = 39;
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          $12 = $15;
        }
      }
    }
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
      var $30 = _parse$$SPACING(193, false);
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
      _fail($2, '\'terminal name\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(180, $2, $3);
    }
    return $3;
  }

  String _parse_sub_terminal_name(int $0, bool $1) {
    if (_memoized(194, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
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
    _success = _c == 64;
    if (_success) {
      $15 = 64;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $16 = _parse$$IDENTIFIER(200, false);
      if (_success) {
        $12 = $15;
      }
    }
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
      var $17 = _parse$$SPACING(201, false);
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
      _fail($2, '\'sub terminal name\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(194, $2, $3);
    }
    return $3;
  }

  String _parse_semantic_value(int $0, bool $1) {
    if (_memoized(202, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    var $8 = _parse$$IDENTIFIER(204, $1);
    if (_success) {
      String $9;
      _success = _c == 58;
      if (_success) {
        $9 = ':';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
      _fail($2, '\'semantic value\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(202, $2, $3);
    }
    return $3;
  }

  String _parse_type_name(int $0, bool $1) {
    if (_memoized(206, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    var $9 = _pos;
    var $10 = $1;
    $1 = false;
    String $11;
    String $12;
    var $13 = _c;
    var $14 = _pos;
    var $15 = _parse$$IDENTIFIER(211, false);
    if (_success) {
      int $16;
      _success = _c == 63;
      if (_success) {
        $16 = 63;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      _success = true;
      $12 = $15;
      // NOP;
    }
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
      var $17 = _parse$$SPACING(214, false);
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
      _fail($2, '\'type name\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(206, $2, $3);
    }
    return $3;
  }

  String _parse_library_prefix(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    String $6;
    var $7 = _pos;
    var $8 = $1;
    $1 = false;
    int $9;
    int $10;
    var $11 = _c;
    var $12 = _pos;
    int $13;
    _success = _c == 95;
    if (_success) {
      $13 = 95;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    _success = true;
    var $14 = _parse$$IDENTIFIER(222, false);
    if (_success) {
      $10 = $13;
    }
    // NOP;
    if (!_success) {
      _c = $11;
      _pos = $12;
    }
    $9 = $10;
    if (_success) {
      $6 = _text.substring($7, _pos);
    }
    $1 = $8;
    if (_success) {
      $5 = $6;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'library prefix\'');
    }
    return $3;
  }

  String _parse_$Semicolon(int $0, bool $1) {
    if (_memoized(223, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 59;
    if (_success) {
      $8 = ';';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(226, false);
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
      _fail($2, '\';\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(223, $2, $3);
    }
    return $3;
  }

  String _parse_action(int $0, bool $1) {
    if (_memoized(227, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
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
      String $9;
      var $10 = _pos;
      var $11 = $1;
      $1 = false;
      List $12;
      List $13;
      List $14;
      for (;;) {
        var $15 = _parse$$ACTION_BODY(234, false);
        if (!_success) {
          break;
        }
      }
      _success = true;
      $13 = $14;
      // NOP;
      $12 = $13;
      if (_success) {
        $9 = _text.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        String $16;
        _success = _c == 125;
        if (_success) {
          $16 = '}';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var $17 = _parse$$SPACING(236, false);
          if (_success) {
            $5 = $9;
          }
        }
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'action\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(227, $2, $3);
    }
    return $3;
  }

  String _parse_$Ampersand(int $0, bool $1) {
    if (_memoized(237, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 38;
    if (_success) {
      $8 = '&';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(240, false);
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
      _fail($2, '\'&\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(237, $2, $3);
    }
    return $3;
  }

  Expression _parse_character_class(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    Expression $3;
    Expression $4;
    Expression $5;
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
      List<List<int>> $9;
      if ($1) {
        $9 = [];
      }
      var $10 = false;
      for (;;) {
        List<int> $11;
        List<int> $12;
        var $13 = _c;
        var $14 = _pos;
        var $15 = _c;
        var $16 = _pos;
        var $17 = _predicate;
        var $18 = $1;
        _predicate = true;
        $1 = false;
        String $19;
        _success = _c == 93;
        if (_success) {
          $19 = ']';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        var $20;
        _success = !_success;
        _c = $15;
        _pos = $16;
        _predicate = $17;
        $1 = $18;
        if (_success) {
          var $21 = _parse$$RANGE(249, $1);
          if (_success) {
            $12 = $21;
          }
        }
        if (!_success) {
          _c = $13;
          _pos = $14;
        }
        $11 = $12;
        if (!_success) {
          _success = $10;
          if (!_success) {
            $9 = null;
          }
          break;
        }
        if ($1) {
          $9.add($11);
        }
        $10 = true;
      }
      if (_success) {
        String $22;
        _success = _c == 93;
        if (_success) {
          $22 = ']';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var $23 = _parse$$SPACING(251, false);
          if (_success) {
            var r = $9;
            Expression $$;
            $$ = CharacterClassExpression(r);
            $5 = $$;
          }
        }
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'character class\'');
    }
    return $3;
  }

  String _parse_$RightParenthesis(int $0, bool $1) {
    if (_memoized(252, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 41;
    if (_success) {
      $8 = ')';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(255, false);
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
      _fail($2, '\')\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(252, $2, $3);
    }
    return $3;
  }

  String _parse_$Period(int $0, bool $1) {
    if (_memoized(256, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 46;
    if (_success) {
      $8 = '.';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(259, false);
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
      _fail($2, '\'.\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(256, $2, $3);
    }
    return $3;
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

  String _parse_globals(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    if (_c == 37) {
      $8 = _matchString('%{');
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      String $9;
      var $10 = _pos;
      var $11 = $1;
      $1 = false;
      List $12;
      List $13;
      List $14;
      for (;;) {
        var $15 = _parse$$GLOBALS_BODY(271, false);
        if (!_success) {
          break;
        }
      }
      _success = true;
      $13 = $14;
      // NOP;
      $12 = $13;
      if (_success) {
        $9 = _text.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        String $16;
        if (_c == 125) {
          $16 = _matchString('}%');
        } else {
          _success = false;
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var $17 = _parse$$SPACING(273, false);
          if (_success) {
            $5 = $9;
          }
        }
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'globals\'');
    }
    return $3;
  }

  List _parse_leading_spaces(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    List $3;
    List $4;
    List $5;
    var $6 = _parse$$SPACING(276, false);
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

  String _parse_$EqualSign(int $0, bool $1) {
    if (_memoized(277, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 61;
    if (_success) {
      $8 = '=';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(280, false);
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
      _fail($2, '\'=\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(277, $2, $3);
    }
    return $3;
  }

  Expression _parse_literal(int $0, bool $1) {
    _fposEnd = -1;
    var $2 = _pos;
    Expression $3;
    Expression $4;
    Expression $5;
    var $6 = _c;
    var $7 = _pos;
    int $8;
    _success = _c == 34;
    if (_success) {
      $8 = 34;
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
        int $10;
        int $11;
        var $12 = _c;
        var $13 = _pos;
        var $14 = _c;
        var $15 = _pos;
        var $16 = _predicate;
        var $17 = $1;
        _predicate = true;
        $1 = false;
        int $18;
        _success = _c == 34;
        if (_success) {
          $18 = 34;
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        var $19;
        _success = !_success;
        _c = $14;
        _pos = $15;
        _predicate = $16;
        $1 = $17;
        if (_success) {
          var $20 = _parse$$LITERAL_CHAR(289, $1);
          if (_success) {
            $11 = $20;
          }
        }
        if (!_success) {
          _c = $12;
          _pos = $13;
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
      int $21;
      _success = _c == 34;
      if (_success) {
        $21 = 34;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        var $22 = _parse$$SPACING(291, false);
        if (_success) {
          var c = $9;
          Expression $$;
          $$ = LiteralExpression(String.fromCharCodes(c));
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
      _fail($2, '\'literal\'');
    }
    return $3;
  }

  String _parse_members(int $0, bool $1) {
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
      String $9;
      var $10 = _pos;
      var $11 = $1;
      $1 = false;
      List $12;
      List $13;
      List $14;
      for (;;) {
        var $15 = _parse$$ACTION_BODY(299, false);
        if (!_success) {
          break;
        }
      }
      _success = true;
      $13 = $14;
      // NOP;
      $12 = $13;
      if (_success) {
        $9 = _text.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        String $16;
        _success = _c == 125;
        if (_success) {
          $16 = '}';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var $17 = _parse$$SPACING(301, false);
          if (_success) {
            $5 = $9;
          }
        }
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _fail($2, '\'members\'');
    }
    return $3;
  }

  String _parse_$ExclamationMark(int $0, bool $1) {
    if (_memoized(302, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 33;
    if (_success) {
      $8 = '!';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(305, false);
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
      _fail($2, '\'!\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(302, $2, $3);
    }
    return $3;
  }

  String _parse_$LeftParenthesis(int $0, bool $1) {
    if (_memoized(306, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 40;
    if (_success) {
      $8 = '(';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(309, false);
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
      _fail($2, '\'(\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(306, $2, $3);
    }
    return $3;
  }

  String _parse_$PlusSign(int $0, bool $1) {
    if (_memoized(310, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 43;
    if (_success) {
      $8 = '+';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(313, false);
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
      _fail($2, '\'+\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(310, $2, $3);
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
      var $9 = _parse$$SPACING(317, false);
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

  String _parse_$QuestionMark(int $0, bool $1) {
    if (_memoized(318, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 63;
    if (_success) {
      $8 = '?';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(321, false);
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
      _fail($2, '\'?\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(318, $2, $3);
    }
    return $3;
  }

  String _parse_$Slash(int $0, bool $1) {
    if (_memoized(322, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 47;
    if (_success) {
      $8 = '/';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(325, false);
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
      _fail($2, '\'/\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(322, $2, $3);
    }
    return $3;
  }

  String _parse_$Asterisk(int $0, bool $1) {
    if (_memoized(326, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 42;
    if (_success) {
      $8 = '*';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(329, false);
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
      _fail($2, '\'*\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(326, $2, $3);
    }
    return $3;
  }

  String _parse_$LessThanSign(int $0, bool $1) {
    if (_memoized(330, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 60;
    if (_success) {
      $8 = '<';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(333, false);
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
      _fail($2, '\'<\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(330, $2, $3);
    }
    return $3;
  }

  String _parse_$GreaterThanSign(int $0, bool $1) {
    if (_memoized(334, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _fposEnd = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _pos;
    String $8;
    _success = _c == 62;
    if (_success) {
      $8 = '>';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      var $9 = _parse$$SPACING(337, false);
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
      _fail($2, '\'>\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(334, $2, $3);
    }
    return $3;
  }

  dynamic _parse$$ACTION_BODY(int $0, bool $1) {
    if (_memoized(338, $0)) {
      return _mresult as dynamic;
    }
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    for (;;) {
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
        List $9;
        for (;;) {
          var $10 = _parse$$ACTION_BODY(342, false);
          if (!_success) {
            break;
          }
        }
        _success = true;
        String $11;
        _success = _c == 125;
        if (_success) {
          $11 = '}';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          $5 = $8;
        }
        // NOP;
      }
      if (!_success) {
        _c = $6;
        _pos = $7;
      } else {
        $4 = $5;
        break;
      }
      // NOP;
      dynamic $12;
      var $13 = _c;
      var $14 = _pos;
      var $15 = _c;
      var $16 = _pos;
      var $17 = _predicate;
      var $18 = $1;
      _predicate = true;
      $1 = false;
      String $19;
      _success = _c == 125;
      if (_success) {
        $19 = '}';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      var $20;
      _success = !_success;
      _c = $15;
      _pos = $16;
      _predicate = $17;
      $1 = $18;
      if (_success) {
        int $21;
        _success = _c < _eof;
        if (_success) {
          $21 = _c;
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          $12 = $20;
        }
      }
      if (!_success) {
        _c = $13;
        _pos = $14;
      } else {
        $4 = $12;
      }
      // NOP;
      break;
    }
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(338, $2, $3);
    }
    return $3;
  }

  String _parse$$COMMENT(int $0, bool $1) {
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _pos;
    String $7;
    _success = _c == 35;
    if (_success) {
      $7 = '#';
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      List $8;
      for (;;) {
        dynamic $9;
        dynamic $10;
        var $11 = _c;
        var $12 = _pos;
        var $13 = _c;
        var $14 = _pos;
        var $15 = _predicate;
        var $16 = $1;
        _predicate = true;
        $1 = false;
        var $17 = _parse$$EOL(355, false);
        var $18;
        _success = !_success;
        _c = $13;
        _pos = $14;
        _predicate = $15;
        $1 = $16;
        if (_success) {
          int $19;
          _success = _c < _eof;
          if (_success) {
            $19 = _c;
            _c = _input[++_pos];
          } else {
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (_success) {
            $10 = $18;
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
      }
      _success = true;
      var $20 = _parse$$EOL(358, false);
      _success = true;
      $4 = $7;
      // NOP;
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

  dynamic _parse$$EOL(int $0, bool $1) {
    if (_memoized(359, $0)) {
      return _mresult as dynamic;
    }
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    for (;;) {
      String $5;
      String $6;
      if (_c == 13) {
        $6 = _matchString('\r\n');
      } else {
        _success = false;
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $5 = $6;
        $4 = $5;
        break;
      }
      // NOP;
      int $7;
      int $8;
      _success = _c == 10 || _c == 13;
      if (_success) {
        $8 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $7 = $8;
        $4 = $7;
      }
      // NOP;
      break;
    }
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(359, $2, $3);
    }
    return $3;
  }

  dynamic _parse$$GLOBALS_BODY(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    dynamic $4;
    var $5 = _c;
    var $6 = _pos;
    var $7 = _c;
    var $8 = _pos;
    var $9 = _predicate;
    var $10 = $1;
    _predicate = true;
    $1 = false;
    String $11;
    if (_c == 125) {
      $11 = _matchString('}%');
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    var $12;
    _success = !_success;
    _c = $7;
    _pos = $8;
    _predicate = $9;
    $1 = $10;
    if (_success) {
      int $13;
      _success = _c < _eof;
      if (_success) {
        $13 = _c;
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $4 = $12;
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

  int _parse$$HEX_NUMBER(int $0, bool $1) {
    if (_memoized(369, $0)) {
      return _mresult as int;
    }
    var $2 = _pos;
    int $3;
    int $4;
    int $5;
    var $6 = _c;
    var $7 = _pos;
    int $8;
    _success = _c == 92;
    if (_success) {
      $8 = 92;
      _c = _input[++_pos];
    } else {
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      String $9;
      _success = _c == 117;
      if (_success) {
        $9 = 'u';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        String $10;
        var $11 = _pos;
        var $12 = $1;
        $1 = false;
        List<int> $13;
        List<int> $14;
        List<int> $15;
        var $16 = false;
        for (;;) {
          int $17;
          if (_c >= 48 && _c <= 57 ||
              _c >= 65 && _c <= 70 ||
              _c >= 97 && _c <= 102) {
            _success = true;
            $17 = _c;
            _c = _input[++_pos];
          } else {
            _success = false;
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (!_success) {
            _success = $16;
            if (!_success) {
              $15 = null;
            }
            break;
          }
          $16 = true;
        }
        if (_success) {
          $14 = $15;
        }
        $13 = $14;
        if (_success) {
          $10 = _text.substring($11, _pos);
        }
        $1 = $12;
        if (_success) {
          var d = $10;
          int $$;
          $$ = int.parse(d, radix: 16);
          $5 = $$;
        }
      }
    }
    if (!_success) {
      _c = $6;
      _pos = $7;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(369, $2, $3);
    }
    return $3;
  }

  String _parse$$IDENTIFIER(int $0, bool $1) {
    if (_memoized(378, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    String $3;
    String $4;
    String $5;
    String $6;
    var $7 = _pos;
    var $8 = $1;
    $1 = false;
    int $9;
    int $10;
    var $11 = _c;
    var $12 = _pos;
    var $13 = _parse$$IDENT_START(383, false);
    if (_success) {
      List<int> $14;
      for (;;) {
        var $15 = _parse$$IDENT_CONT(385, false);
        if (!_success) {
          break;
        }
      }
      _success = true;
      $10 = $13;
      // NOP;
    }
    if (!_success) {
      _c = $11;
      _pos = $12;
    }
    $9 = $10;
    if (_success) {
      $6 = _text.substring($7, _pos);
    }
    $1 = $8;
    if (_success) {
      $5 = $6;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(378, $2, $3);
    }
    return $3;
  }

  int _parse$$IDENT_CONT(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _parse$$IDENT_START(388, false);
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      int $6;
      int $7;
      if (_c >= 48 && _c <= 57 || _c == 95) {
        _success = true;
        $7 = _c;
        _c = _input[++_pos];
      } else {
        _success = false;
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        $6 = $7;
        $3 = $6;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  int _parse$$IDENT_START(int $0, bool $1) {
    if (_memoized(391, $0)) {
      return _mresult as int;
    }
    var $2 = _pos;
    int $3;
    int $4;
    int $5;
    int $6;
    if (_c >= 65 && _c <= 90 || _c >= 97 && _c <= 122) {
      _success = true;
      $6 = _c;
      _c = _input[++_pos];
    } else {
      _success = false;
      if (_fposEnd < _pos) {
        _fposEnd = _pos;
      }
    }
    if (_success) {
      $5 = $6;
    }
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(391, $2, $3);
    }
    return $3;
  }

  int _parse$$LITERAL_CHAR(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _c;
      var $6 = _pos;
      String $7;
      _success = _c == 92;
      if (_success) {
        $7 = '\\';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $8;
        if (_c == 34 || _c == 92 || _c == 110 || _c == 114 || _c == 116) {
          _success = true;
          $8 = _c;
          _c = _input[++_pos];
        } else {
          _success = false;
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var c = $8;
          int $$;
          $$ = _escape(c);
          $4 = $$;
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
      var $10 = _parse$$HEX_NUMBER(399, $1);
      if (_success) {
        $9 = $10;
        $3 = $9;
        break;
      }
      // NOP;
      int $11;
      var $12 = _c;
      var $13 = _pos;
      var $14 = _c;
      var $15 = _pos;
      var $16 = _predicate;
      var $17 = $1;
      _predicate = true;
      $1 = false;
      String $18;
      _success = _c == 92;
      if (_success) {
        $18 = '\\';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      var $19;
      _success = !_success;
      _c = $14;
      _pos = $15;
      _predicate = $16;
      $1 = $17;
      if (_success) {
        var $20 = _c;
        var $21 = _pos;
        var $22 = _predicate;
        var $23 = $1;
        _predicate = true;
        $1 = false;
        var $24 = _parse$$EOL(404, false);
        var $25;
        _success = !_success;
        _c = $20;
        _pos = $21;
        _predicate = $22;
        $1 = $23;
        if (_success) {
          int $26;
          _success = _c < _eof;
          if (_success) {
            $26 = _c;
            _c = _input[++_pos];
          } else {
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (_success) {
            $11 = $26;
          }
        }
      }
      if (!_success) {
        _c = $12;
        _pos = $13;
      } else {
        $3 = $11;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  List<int> _parse$$RANGE(int $0, bool $1) {
    List<int> $2;
    List<int> $3;
    for (;;) {
      List<int> $4;
      var $5 = _c;
      var $6 = _pos;
      var $7 = _parse$$RANGE_CHAR(408, $1);
      if (_success) {
        String $8;
        _success = _c == 45;
        if (_success) {
          $8 = '-';
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var $9 = _parse$$RANGE_CHAR(410, $1);
          if (_success) {
            var s = $7;
            var e = $9;
            List<int> $$;
            $$ = [s, e];
            $4 = $$;
          }
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
      List<int> $10;
      var $11 = _parse$$RANGE_CHAR(412, $1);
      if (_success) {
        var c = $11;
        List<int> $$;
        $$ = [c, c];
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

  int _parse$$RANGE_CHAR(int $0, bool $1) {
    if (_memoized(413, $0)) {
      return _mresult as int;
    }
    var $2 = _pos;
    int $3;
    int $4;
    for (;;) {
      int $5;
      var $6 = _c;
      var $7 = _pos;
      String $8;
      _success = _c == 92;
      if (_success) {
        $8 = '\\';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $9;
        if (_c == 45 ||
            _c >= 92 && _c <= 93 ||
            _c == 110 ||
            _c == 114 ||
            _c == 116) {
          _success = true;
          $9 = _c;
          _c = _input[++_pos];
        } else {
          _success = false;
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
        if (_success) {
          var c = $9;
          int $$;
          $$ = _escape(c);
          $5 = $$;
        }
      }
      if (!_success) {
        _c = $6;
        _pos = $7;
      } else {
        $4 = $5;
        break;
      }
      // NOP;
      int $10;
      var $11 = _parse$$HEX_NUMBER(418, $1);
      if (_success) {
        $10 = $11;
        $4 = $10;
        break;
      }
      // NOP;
      int $12;
      var $13 = _c;
      var $14 = _pos;
      var $15 = _c;
      var $16 = _pos;
      var $17 = _predicate;
      var $18 = $1;
      _predicate = true;
      $1 = false;
      String $19;
      _success = _c == 92;
      if (_success) {
        $19 = '\\';
        _c = _input[++_pos];
      } else {
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      var $20;
      _success = !_success;
      _c = $15;
      _pos = $16;
      _predicate = $17;
      $1 = $18;
      if (_success) {
        var $21 = _c;
        var $22 = _pos;
        var $23 = _predicate;
        var $24 = $1;
        _predicate = true;
        $1 = false;
        var $25 = _parse$$EOL(423, false);
        var $26;
        _success = !_success;
        _c = $21;
        _pos = $22;
        _predicate = $23;
        $1 = $24;
        if (_success) {
          int $27;
          _success = _c < _eof;
          if (_success) {
            $27 = _c;
            _c = _input[++_pos];
          } else {
            if (_fposEnd < _pos) {
              _fposEnd = _pos;
            }
          }
          if (_success) {
            $12 = $27;
          }
        }
      }
      if (!_success) {
        _c = $13;
        _pos = $14;
      } else {
        $4 = $12;
      }
      // NOP;
      break;
    }
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(413, $2, $3);
    }
    return $3;
  }

  dynamic _parse$$SPACE(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    for (;;) {
      int $4;
      int $5;
      _success = _c == 9 || _c == 32;
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
      dynamic $6;
      var $7 = _parse$$EOL(429, false);
      if (_success) {
        $6 = $7;
        $3 = $6;
      }
      // NOP;
      break;
    }
    $2 = $3;
    return $2;
  }

  List _parse$$SPACING(int $0, bool $1) {
    if (_memoized(430, $0)) {
      return _mresult as List;
    }
    var $2 = _pos;
    List $3;
    List $4;
    List $5;
    List $6;
    for (;;) {
      dynamic $7;
      for (;;) {
        dynamic $8;
        var $9 = _parse$$SPACE(435, false);
        if (_success) {
          $8 = $9;
          $7 = $8;
          break;
        }
        // NOP;
        String $10;
        var $11 = _parse$$COMMENT(437, false);
        if (_success) {
          $10 = $11;
          $7 = $10;
        }
        // NOP;
        break;
      }
      if (!_success) {
        break;
      }
    }
    _success = true;
    $5 = $6;
    // NOP;
    $4 = $5;
    $3 = $4;
    if (_memoizable[$0] == true) {
      _memoize(430, $2, $3);
    }
    return $3;
  }

  int _parse$$TERMINAL_CHAR(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _c;
      var $6 = _pos;
      String $7;
      if (_c == 47) {
        $7 = _matchString('//');
      } else {
        _success = false;
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
      if (_success) {
        int $8;
        _success = _c == 39;
        if (_success) {
          $8 = 39;
          _c = _input[++_pos];
        } else {
          if (_fposEnd < _pos) {
            _fposEnd = _pos;
          }
        }
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
      int $10;
      if (_c >= 32 && _c <= 38 || _c >= 40 && _c <= 126) {
        _success = true;
        $10 = _c;
        _c = _input[++_pos];
      } else {
        _success = false;
        if (_fposEnd < _pos) {
          _fposEnd = _pos;
        }
      }
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
