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

  List<int> _trackCid;

  List<int> _trackPos;

  dynamic parse(String text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
    _input = text;
    _reset();
    final result = _parseGrammar(0, true);
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

  void _reset() {
    _c = _eof;
    _cp = -1;
    _failurePos = -1;
    _hasMalformed = false;
    _memoizable = [];
    _memoizable.length = 444;
    _memos = [];
    _memos.length = _input.length + 1;
    _pos = 0;
    _predicate = false;
    _states = [];
    _states.length = 20 * 3;
    _terminalCount = 0;
    _terminals = [];
    _terminals.length = 20;
    _trackCid = [];
    _trackCid.length = 444;
    _trackPos = [];
    _trackPos.length = 444;
  }

  Grammar _parseGrammar(int $0, bool $1) {
    Grammar $2;
    Grammar $3;
    Grammar $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _parse_leading_spaces(3, false);
    _success = true;
    var $9 = _parse_globals(5, $1);
    _success = true;
    var $10 = _parse_members(7, $1);
    _success = true;
    List<ProductionRule> $11;
    if ($1) {
      $11 = [];
    }
    var $12 = false;
    for (;;) {
      var $13 = _parseDefinition(9, $1);
      if (!_success) {
        _success = $12;
        if (!_success) {
          $11 = null;
        }
        break;
      }
      if ($1) {
        $11.add($13);
      }
      $12 = true;
    }
    if (_success) {
      _parse_end_of_file(10, false);
      if (_success) {
        var g = $9;
        var m = $10;
        var d = $11;
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
      _cp = $6;
      _pos = $7;
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
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _parseType(20, $1);
      if (_success) {
        var $9 = _parse_non_terminal_name(21, $1);
        if (_success) {
          _parse_$EqualSign(22, false);
          if (_success) {
            var $11 = _parseNonterminalExpression(23, $1);
            if (_success) {
              _parse_$Semicolon(24, false);
              if (_success) {
                var t = $8;
                var n = $9;
                var e = $11;
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
        _cp = $6;
        _pos = $7;
      } else {
        $3 = $4;
        break;
      }
      // NOP;
      ProductionRule $13;
      var $14 = _c;
      var $15 = _cp;
      var $16 = _pos;
      var $17 = _parse_non_terminal_name(26, $1);
      if (_success) {
        _parse_$EqualSign(27, false);
        if (_success) {
          var $19 = _parseNonterminalExpression(28, $1);
          if (_success) {
            _parse_$Semicolon(29, false);
            if (_success) {
              var n = $17;
              var e = $19;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Nonterminal, e, null);
              $13 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $14;
        _cp = $15;
        _pos = $16;
      } else {
        $3 = $13;
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
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _parseNonterminalSequence(32, $1);
    if (_success) {
      List<SequenceExpression> $10;
      if ($1) {
        $10 = [];
      }
      for (;;) {
        SequenceExpression $11;
        SequenceExpression $12;
        var $13 = _c;
        var $14 = _cp;
        var $15 = _pos;
        _parse_$Slash(36, false);
        if (_success) {
          var $17 = _parseNonterminalSequence(37, $1);
          if (_success) {
            $12 = $17;
          }
        }
        if (!_success) {
          _c = $13;
          _cp = $14;
          _pos = $15;
        }
        $11 = $12;
        if (!_success) {
          break;
        }
        if ($1) {
          $10.add($11);
        }
      }
      _success = true;
      {
        var e = $9;
        var n = $10;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
    var $7 = _cp;
    var $8 = _pos;
    List<Expression> $9;
    if ($1) {
      $9 = [];
    }
    var $10 = false;
    for (;;) {
      var $11 = _parseNonterminalPrefix(41, $1);
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
      var $12 = _parse_action(43, $1);
      _success = true;
      {
        var e = $9;
        var a = $12;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse_semantic_value(47, $1);
    _success = true;
    String $9;
    for (;;) {
      String $10;
      var $11 = _parse_$Ampersand(51, $1);
      if (_success) {
        $10 = $11;
        $9 = $10;
        break;
      }
      // NOP;
      String $12;
      var $13 = _parse_$ExclamationMark(53, $1);
      if (_success) {
        $12 = $13;
        $9 = $12;
      }
      // NOP;
      break;
    }
    _success = true;
    var $14 = _parseNonterminalSuffix(54, $1);
    if (_success) {
      var s = $8;
      var p = $9;
      var e = $14;
      Expression $$;
      $$ = _prefix(p, e, s);
      $4 = $$;
    }
    // NOP;
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

  Expression _parseNonterminalSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseNonterminalPrimary(57, $1);
    if (_success) {
      String $9;
      for (;;) {
        String $10;
        var $11 = _parse_$QuestionMark(61, $1);
        if (_success) {
          $10 = $11;
          $9 = $10;
          break;
        }
        // NOP;
        String $12;
        var $13 = _parse_$Asterisk(63, $1);
        if (_success) {
          $12 = $13;
          $9 = $12;
          break;
        }
        // NOP;
        String $14;
        var $15 = _parse_$PlusSign(65, $1);
        if (_success) {
          $14 = $15;
          $9 = $14;
        }
        // NOP;
        break;
      }
      _success = true;
      {
        var e = $8;
        var s = $9;
        Expression $$;
        $$ = _suffix(s, e);
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
      var $10 = _cp;
      var $11 = _pos;
      _parse_$LeftParenthesis(72, false);
      if (_success) {
        var $13 = _parseNonterminalExpression(73, $1);
        if (_success) {
          _parse_$RightParenthesis(74, false);
          if (_success) {
            $8 = $13;
          }
        }
      }
      if (!_success) {
        _c = $9;
        _cp = $10;
        _pos = $11;
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
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _parseType(77, $1);
      if (_success) {
        var $9 = _parse_terminal_name(78, $1);
        if (_success) {
          _parse_$EqualSign(79, false);
          if (_success) {
            var $11 = _parseExpression(80, $1);
            if (_success) {
              _parse_$Semicolon(81, false);
              if (_success) {
                var t = $8;
                var n = $9;
                var e = $11;
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
        _cp = $6;
        _pos = $7;
      } else {
        $3 = $4;
        break;
      }
      // NOP;
      ProductionRule $13;
      var $14 = _c;
      var $15 = _cp;
      var $16 = _pos;
      var $17 = _parse_terminal_name(83, $1);
      if (_success) {
        _parse_$EqualSign(84, false);
        if (_success) {
          var $19 = _parseExpression(85, $1);
          if (_success) {
            _parse_$Semicolon(86, false);
            if (_success) {
              var n = $17;
              var e = $19;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Terminal, e, null);
              $13 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $14;
        _cp = $15;
        _pos = $16;
      } else {
        $3 = $13;
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
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _parseSequence(89, $1);
    if (_success) {
      List<SequenceExpression> $10;
      if ($1) {
        $10 = [];
      }
      for (;;) {
        SequenceExpression $11;
        SequenceExpression $12;
        var $13 = _c;
        var $14 = _cp;
        var $15 = _pos;
        _parse_$Slash(93, false);
        if (_success) {
          var $17 = _parseSequence(94, $1);
          if (_success) {
            $12 = $17;
          }
        }
        if (!_success) {
          _c = $13;
          _cp = $14;
          _pos = $15;
        }
        $11 = $12;
        if (!_success) {
          break;
        }
        if ($1) {
          $10.add($11);
        }
      }
      _success = true;
      {
        var e = $9;
        var n = $10;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
    var $7 = _cp;
    var $8 = _pos;
    List<Expression> $9;
    if ($1) {
      $9 = [];
    }
    var $10 = false;
    for (;;) {
      var $11 = _parsePrefix(98, $1);
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
      var $12 = _parse_action(100, $1);
      _success = true;
      {
        var e = $9;
        var a = $12;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse_semantic_value(104, $1);
    _success = true;
    String $9;
    for (;;) {
      String $10;
      var $11 = _parse_$Ampersand(108, $1);
      if (_success) {
        $10 = $11;
        $9 = $10;
        break;
      }
      // NOP;
      String $12;
      var $13 = _parse_$ExclamationMark(110, $1);
      if (_success) {
        $12 = $13;
        $9 = $12;
      }
      // NOP;
      break;
    }
    _success = true;
    var $14 = _parseSuffix(111, $1);
    if (_success) {
      var s = $8;
      var p = $9;
      var e = $14;
      Expression $$;
      $$ = _prefix(p, e, s);
      $4 = $$;
    }
    // NOP;
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

  Expression _parseSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parsePrimary(114, $1);
    if (_success) {
      String $9;
      for (;;) {
        String $10;
        var $11 = _parse_$QuestionMark(118, $1);
        if (_success) {
          $10 = $11;
          $9 = $10;
          break;
        }
        // NOP;
        String $12;
        var $13 = _parse_$Asterisk(120, $1);
        if (_success) {
          $12 = $13;
          $9 = $12;
          break;
        }
        // NOP;
        String $14;
        var $15 = _parse_$PlusSign(122, $1);
        if (_success) {
          $14 = $15;
          $9 = $14;
        }
        // NOP;
        break;
      }
      _success = true;
      {
        var e = $8;
        var s = $9;
        Expression $$;
        $$ = _suffix(s, e);
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
      var $8 = _cp;
      var $9 = _pos;
      _parse_$LeftParenthesis(127, false);
      if (_success) {
        var $11 = _parseExpression(128, $1);
        if (_success) {
          _parse_$RightParenthesis(129, false);
          if (_success) {
            $6 = $11;
          }
        }
      }
      if (!_success) {
        _c = $7;
        _cp = $8;
        _pos = $9;
      } else {
        $3 = $6;
        break;
      }
      // NOP;
      Expression $13;
      var $14 = _parse_literal(131, $1);
      if (_success) {
        $13 = $14;
        $3 = $13;
        break;
      }
      // NOP;
      Expression $15;
      var $16 = _parse_character_class(133, $1);
      if (_success) {
        $15 = $16;
        $3 = $15;
        break;
      }
      // NOP;
      Expression $17;
      _parse_$Period(135, $1);
      if (_success) {
        Expression $$;
        $$ = AnyCharacterExpression();
        $17 = $$;
      }
      if (_success) {
        $3 = $17;
        break;
      }
      Expression $19;
      var $20 = _c;
      var $21 = _cp;
      var $22 = _pos;
      _parse_$LessThanSign(137, false);
      if (_success) {
        var $24 = _parseExpression(138, $1);
        if (_success) {
          _parse_$GreaterThanSign(139, false);
          if (_success) {
            var e = $24;
            Expression $$;
            $$ = CaptureExpression(e);
            $19 = $$;
          }
        }
      }
      if (!_success) {
        _c = $20;
        _cp = $21;
        _pos = $22;
      } else {
        $3 = $19;
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
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _parseType(142, $1);
      if (_success) {
        var $9 = _parse_sub_terminal_name(143, $1);
        if (_success) {
          _parse_$EqualSign(144, false);
          if (_success) {
            var $11 = _parseExpression(145, $1);
            if (_success) {
              _parse_$Semicolon(146, false);
              if (_success) {
                var t = $8;
                var n = $9;
                var e = $11;
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
        _cp = $6;
        _pos = $7;
      } else {
        $3 = $4;
        break;
      }
      // NOP;
      ProductionRule $13;
      var $14 = _c;
      var $15 = _cp;
      var $16 = _pos;
      var $17 = _parse_sub_terminal_name(148, $1);
      if (_success) {
        _parse_$EqualSign(149, false);
        if (_success) {
          var $19 = _parseExpression(150, $1);
          if (_success) {
            _parse_$Semicolon(151, false);
            if (_success) {
              var n = $17;
              var e = $19;
              ProductionRule $$;
              $$ = ProductionRule(n, ProductionRuleKind.Subterminal, e, null);
              $13 = $$;
            }
          }
        }
      }
      if (!_success) {
        _c = $14;
        _cp = $15;
        _pos = $16;
      } else {
        $3 = $13;
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
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _parseTypeName(154, $1);
    if (_success) {
      List<String> $10;
      List<String> $11;
      var $12 = _c;
      var $13 = _cp;
      var $14 = _pos;
      _parse_$LessThanSign(158, false);
      if (_success) {
        var $16 = _parseTypeArguments(159, $1);
        if (_success) {
          _parse_$GreaterThanSign(160, false);
          if (_success) {
            $11 = $16;
          }
        }
      }
      if (!_success) {
        _c = $12;
        _cp = $13;
        _pos = $14;
      }
      $10 = $11;
      _success = true;
      {
        var n = $9;
        var a = $10;
        String $$;
        $$ = n + (a == null ? '' : '<' + a.join(', ') + '>');
        $5 = $$;
      }
      // NOP;
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _parse_library_prefix(163, $1);
      if (_success) {
        _parse_$Period(164, false);
        if (_success) {
          var $10 = _parse_type_name(165, $1);
          if (_success) {
            var p = $8;
            var n = $10;
            String $$;
            $$ = '$p.$n';
            $4 = $$;
          }
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
      String $11;
      var $12 = _parse_type_name(167, $1);
      if (_success) {
        $11 = $12;
        $3 = $11;
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
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseType(170, $1);
    if (_success) {
      List<String> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        String $10;
        String $11;
        var $12 = _c;
        var $13 = _cp;
        var $14 = _pos;
        _parse_$Comma(174, false);
        if (_success) {
          var $16 = _parseType(175, $1);
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
        var t = $8;
        var n = $9;
        List<String> $$;
        $$ = [t, ...n];
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

  String _parse_non_terminal_name(int $0, bool $1) {
    if (_memoized(176, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _parse$$IDENTIFIER(178, $1);
    if (_success) {
      _parse$$SPACING(179, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'non terminal name\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    String $9;
    var $10 = _pos;
    var $11 = $1;
    $1 = false;
    int $12;
    int $13;
    var $14 = _c;
    var $15 = _cp;
    var $16 = _pos;
    var $17 = _matchChar(39);
    if (_success) {
      List $18;
      if ($1) {
        $18 = [];
      }
      var $19 = false;
      for (;;) {
        dynamic $20;
        dynamic $21;
        var $22 = _c;
        var $23 = _cp;
        var $24 = _pos;
        var $25 = _c;
        var $26 = _cp;
        var $27 = _pos;
        var $28 = _predicate;
        var $29 = $1;
        _predicate = true;
        $1 = false;
        _matchChar(39);
        var $31;
        _success = !_success;
        _c = $25;
        _cp = $26;
        _pos = $27;
        _predicate = $28;
        $1 = $29;
        if (_success) {
          _parse$$TERMINAL_CHAR(191, false);
          if (_success) {
            $21 = $31;
          }
        }
        if (!_success) {
          _c = $22;
          _cp = $23;
          _pos = $24;
        }
        $20 = $21;
        if (!_success) {
          _success = $19;
          if (!_success) {
            $18 = null;
          }
          break;
        }
        if ($1) {
          $18.add($20);
        }
        $19 = true;
      }
      if (_success) {
        _matchChar(39);
        if (_success) {
          $13 = $17;
        }
      }
    }
    if (!_success) {
      _c = $14;
      _cp = $15;
      _pos = $16;
    }
    $12 = $13;
    if (_success) {
      $9 = _input.substring($10, _pos);
    }
    $1 = $11;
    if (_success) {
      _parse$$SPACING(193, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'terminal name\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    String $9;
    var $10 = _pos;
    var $11 = $1;
    $1 = false;
    int $12;
    int $13;
    var $14 = _c;
    var $15 = _cp;
    var $16 = _pos;
    var $17 = _matchChar(64);
    if (_success) {
      _parse$$IDENTIFIER(200, false);
      if (_success) {
        $13 = $17;
      }
    }
    if (!_success) {
      _c = $14;
      _cp = $15;
      _pos = $16;
    }
    $12 = $13;
    if (_success) {
      $9 = _input.substring($10, _pos);
    }
    $1 = $11;
    if (_success) {
      _parse$$SPACING(201, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'sub terminal name\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _parse$$IDENTIFIER(204, $1);
    if (_success) {
      _matchString(':');
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'semantic value\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    String $9;
    var $10 = _pos;
    var $11 = $1;
    $1 = false;
    String $12;
    String $13;
    var $14 = _c;
    var $15 = _cp;
    var $16 = _pos;
    var $17 = _parse$$IDENTIFIER(211, $1);
    if (_success) {
      _matchChar(63);
      _success = true;
      $13 = $17;
      // NOP;
    }
    if (!_success) {
      _c = $14;
      _cp = $15;
      _pos = $16;
    }
    $12 = $13;
    if (_success) {
      $9 = _input.substring($10, _pos);
    }
    $1 = $11;
    if (_success) {
      _parse$$SPACING(214, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'type name\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(206, $2, $3);
    }
    return $3;
  }

  String _parse_library_prefix(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    String $5;
    var $6 = _pos;
    var $7 = $1;
    $1 = false;
    int $8;
    int $9;
    var $10 = _c;
    var $11 = _cp;
    var $12 = _pos;
    var $13 = _matchChar(95);
    _success = true;
    _parse$$IDENTIFIER(222, false);
    if (_success) {
      $9 = $13;
    }
    // NOP;
    if (!_success) {
      _c = $10;
      _cp = $11;
      _pos = $12;
    }
    $8 = $9;
    if (_success) {
      $5 = _input.substring($6, _pos);
    }
    $1 = $7;
    if (_success) {
      $4 = $5;
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'library prefix\'');
    }
    return $2;
  }

  String _parse_$Semicolon(int $0, bool $1) {
    if (_memoized(223, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString(';');
    if (_success) {
      _parse$$SPACING(226, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\';\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    _matchString('{');
    if (_success) {
      String $10;
      var $11 = _pos;
      var $12 = $1;
      $1 = false;
      List $13;
      List $14;
      List $15;
      if ($1) {
        $15 = [];
      }
      for (;;) {
        var $16 = _parse$$ACTION_BODY(234, $1);
        if (!_success) {
          break;
        }
        if ($1) {
          $15.add($16);
        }
      }
      _success = true;
      $14 = $15;
      // NOP;
      $13 = $14;
      if (_success) {
        $10 = _input.substring($11, _pos);
      }
      $1 = $12;
      if (_success) {
        _matchString('}');
        if (_success) {
          _parse$$SPACING(236, false);
          if (_success) {
            $5 = $10;
          }
        }
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'action\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('&');
    if (_success) {
      _parse$$SPACING(240, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'&\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(237, $2, $3);
    }
    return $3;
  }

  Expression _parse_character_class(int $0, bool $1) {
    _failed = -1;
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('[');
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
        var $14 = _cp;
        var $15 = _pos;
        var $16 = _c;
        var $17 = _cp;
        var $18 = _pos;
        var $19 = _predicate;
        var $20 = $1;
        _predicate = true;
        $1 = false;
        _matchString(']');
        // NOP;
        _success = !_success;
        _c = $16;
        _cp = $17;
        _pos = $18;
        _predicate = $19;
        $1 = $20;
        if (_success) {
          var $23 = _parse$$RANGE(249, $1);
          if (_success) {
            $12 = $23;
          }
        }
        if (!_success) {
          _c = $13;
          _cp = $14;
          _pos = $15;
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
        _matchString(']');
        if (_success) {
          _parse$$SPACING(251, false);
          if (_success) {
            var r = $9;
            Expression $$;
            $$ = CharacterClassExpression(r);
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
    if (!_success) {
      _failure('\'character class\'');
    }
    return $2;
  }

  String _parse_$RightParenthesis(int $0, bool $1) {
    if (_memoized(252, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString(')');
    if (_success) {
      _parse$$SPACING(255, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\')\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('.');
    if (_success) {
      _parse$$SPACING(259, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'.\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(256, $2, $3);
    }
    return $3;
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

  String _parse_globals(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('%{');
    if (_success) {
      String $9;
      var $10 = _pos;
      var $11 = $1;
      $1 = false;
      List $12;
      List $13;
      List $14;
      if ($1) {
        $14 = [];
      }
      for (;;) {
        var $15 = _parse$$GLOBALS_BODY(271, $1);
        if (!_success) {
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      _success = true;
      $13 = $14;
      // NOP;
      $12 = $13;
      if (_success) {
        $9 = _input.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        _matchString('}%');
        if (_success) {
          _parse$$SPACING(273, false);
          if (_success) {
            $4 = $9;
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
    if (!_success) {
      _failure('\'globals\'');
    }
    return $2;
  }

  List _parse_leading_spaces(int $0, bool $1) {
    _failed = -1;
    List $2;
    List $3;
    List $4;
    var $5 = _parse$$SPACING(276, $1);
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

  String _parse_$EqualSign(int $0, bool $1) {
    if (_memoized(277, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('=');
    if (_success) {
      _parse$$SPACING(280, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'=\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(277, $2, $3);
    }
    return $3;
  }

  Expression _parse_literal(int $0, bool $1) {
    _failed = -1;
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchChar(34);
    if (_success) {
      List<int> $9;
      if ($1) {
        $9 = [];
      }
      for (;;) {
        int $10;
        int $11;
        var $12 = _c;
        var $13 = _cp;
        var $14 = _pos;
        var $15 = _c;
        var $16 = _cp;
        var $17 = _pos;
        var $18 = _predicate;
        var $19 = $1;
        _predicate = true;
        $1 = false;
        _matchChar(34);
        // NOP;
        _success = !_success;
        _c = $15;
        _cp = $16;
        _pos = $17;
        _predicate = $18;
        $1 = $19;
        if (_success) {
          var $22 = _parse$$LITERAL_CHAR(289, $1);
          if (_success) {
            $11 = $22;
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
      _matchChar(34);
      if (_success) {
        _parse$$SPACING(291, false);
        if (_success) {
          var c = $9;
          Expression $$;
          $$ = LiteralExpression(String.fromCharCodes(c));
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
      _failure('\'literal\'');
    }
    return $2;
  }

  String _parse_members(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchString('{');
    if (_success) {
      String $9;
      var $10 = _pos;
      var $11 = $1;
      $1 = false;
      List $12;
      List $13;
      List $14;
      if ($1) {
        $14 = [];
      }
      for (;;) {
        var $15 = _parse$$ACTION_BODY(299, $1);
        if (!_success) {
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      _success = true;
      $13 = $14;
      // NOP;
      $12 = $13;
      if (_success) {
        $9 = _input.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        _matchString('}');
        if (_success) {
          _parse$$SPACING(301, false);
          if (_success) {
            $4 = $9;
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
    if (!_success) {
      _failure('\'members\'');
    }
    return $2;
  }

  String _parse_$ExclamationMark(int $0, bool $1) {
    if (_memoized(302, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('!');
    if (_success) {
      _parse$$SPACING(305, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'!\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('(');
    if (_success) {
      _parse$$SPACING(309, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'(\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('+');
    if (_success) {
      _parse$$SPACING(313, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'+\'');
    }
    if (_memoizable[$0] == true) {
      _memoize(310, $2, $3);
    }
    return $3;
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
      _parse$$SPACING(317, false);
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

  String _parse_$QuestionMark(int $0, bool $1) {
    if (_memoized(318, $0)) {
      return _mresult as String;
    }
    var $2 = _pos;
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('?');
    if (_success) {
      _parse$$SPACING(321, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'?\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('/');
    if (_success) {
      _parse$$SPACING(325, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'/\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('*');
    if (_success) {
      _parse$$SPACING(329, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'*\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('<');
    if (_success) {
      _parse$$SPACING(333, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'<\'');
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
    _failed = -1;
    String $3;
    String $4;
    String $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    var $9 = _matchString('>');
    if (_success) {
      _parse$$SPACING(337, false);
      if (_success) {
        $5 = $9;
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
    }
    $4 = $5;
    $3 = $4;
    if (!_success) {
      _failure('\'>\'');
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
      var $7 = _cp;
      var $8 = _pos;
      var $9 = _matchString('{');
      if (_success) {
        List $10;
        if ($1) {
          $10 = [];
        }
        for (;;) {
          var $11 = _parse$$ACTION_BODY(342, false);
          if (!_success) {
            break;
          }
          if ($1) {
            $10.add($11);
          }
        }
        _success = true;
        _matchString('}');
        if (_success) {
          $5 = $9;
        }
        // NOP;
      }
      if (!_success) {
        _c = $6;
        _cp = $7;
        _pos = $8;
      } else {
        $4 = $5;
        break;
      }
      // NOP;
      dynamic $13;
      var $14 = _c;
      var $15 = _cp;
      var $16 = _pos;
      var $17 = _c;
      var $18 = _cp;
      var $19 = _pos;
      var $20 = _predicate;
      var $21 = $1;
      _predicate = true;
      $1 = false;
      _matchString('}');
      var $23;
      _success = !_success;
      _c = $17;
      _cp = $18;
      _pos = $19;
      _predicate = $20;
      $1 = $21;
      if (_success) {
        _matchAny();
        if (_success) {
          $13 = $23;
        }
      }
      if (!_success) {
        _c = $14;
        _cp = $15;
        _pos = $16;
      } else {
        $4 = $13;
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
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('#');
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
        var $15 = _c;
        var $16 = _cp;
        var $17 = _pos;
        var $18 = _predicate;
        var $19 = $1;
        _predicate = true;
        $1 = false;
        _parse$$EOL(355, $1);
        var $21;
        _success = !_success;
        _c = $15;
        _cp = $16;
        _pos = $17;
        _predicate = $18;
        $1 = $19;
        if (_success) {
          _matchAny();
          if (_success) {
            $11 = $21;
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
      _parse$$EOL(358, false);
      _success = true;
      $4 = $8;
      // NOP;
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

  dynamic _parse$$EOL(int $0, bool $1) {
    if (_memoized(359, $0)) {
      return _mresult as dynamic;
    }
    var $2 = _pos;
    dynamic $3;
    dynamic $4;
    for (;;) {
      String $5;
      var $6 = _matchString('\r\n');
      if (_success) {
        $5 = $6;
        $4 = $5;
        break;
      }
      // NOP;
      int $7;
      const $8 = [10, 10, 13, 13];
      var $9 = _matchRanges($8);
      if (_success) {
        $7 = $9;
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
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _c;
    var $9 = _cp;
    var $10 = _pos;
    var $11 = _predicate;
    var $12 = $1;
    _predicate = true;
    $1 = false;
    _matchString('}%');
    var $14;
    _success = !_success;
    _c = $8;
    _cp = $9;
    _pos = $10;
    _predicate = $11;
    $1 = $12;
    if (_success) {
      _matchAny();
      if (_success) {
        $4 = $14;
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

  int _parse$$HEX_NUMBER(int $0, bool $1) {
    if (_memoized(369, $0)) {
      return _mresult as int;
    }
    var $2 = _pos;
    int $3;
    int $4;
    int $5;
    var $6 = _c;
    var $7 = _cp;
    var $8 = _pos;
    _matchChar(92);
    if (_success) {
      _matchString('u');
      if (_success) {
        String $11;
        var $12 = _pos;
        var $13 = $1;
        $1 = false;
        List<int> $14;
        List<int> $15;
        List<int> $16;
        if ($1) {
          $16 = [];
        }
        var $17 = false;
        for (;;) {
          const $18 = [48, 57, 65, 70, 97, 102];
          var $19 = _matchRanges($18);
          if (!_success) {
            _success = $17;
            if (!_success) {
              $16 = null;
            }
            break;
          }
          if ($1) {
            $16.add($19);
          }
          $17 = true;
        }
        if (_success) {
          $15 = $16;
        }
        $14 = $15;
        if (_success) {
          $11 = _input.substring($12, _pos);
        }
        $1 = $13;
        if (_success) {
          var d = $11;
          int $$;
          $$ = int.parse(d, radix: 16);
          $5 = $$;
        }
      }
    }
    if (!_success) {
      _c = $6;
      _cp = $7;
      _pos = $8;
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
    var $12 = _cp;
    var $13 = _pos;
    var $14 = _parse$$IDENT_START(383, $1);
    if (_success) {
      List<int> $15;
      if ($1) {
        $15 = [];
      }
      for (;;) {
        var $16 = _parse$$IDENT_CONT(385, false);
        if (!_success) {
          break;
        }
        if ($1) {
          $15.add($16);
        }
      }
      _success = true;
      $10 = $14;
      // NOP;
    }
    if (!_success) {
      _c = $11;
      _cp = $12;
      _pos = $13;
    }
    $9 = $10;
    if (_success) {
      $6 = _input.substring($7, _pos);
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
      var $5 = _parse$$IDENT_START(388, $1);
      if (_success) {
        $4 = $5;
        $3 = $4;
        break;
      }
      // NOP;
      int $6;
      const $7 = [48, 57, 95, 95];
      var $8 = _matchRanges($7);
      if (_success) {
        $6 = $8;
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
    const $6 = [65, 90, 97, 122];
    var $7 = _matchRanges($6);
    if (_success) {
      $5 = $7;
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
      var $6 = _cp;
      var $7 = _pos;
      _matchString('\\');
      if (_success) {
        const $9 = [34, 34, 92, 92, 110, 110, 114, 114, 116, 116];
        var $10 = _matchRanges($9);
        if (_success) {
          var c = $10;
          int $$;
          $$ = _escape(c);
          $4 = $$;
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
      int $11;
      var $12 = _parse$$HEX_NUMBER(399, $1);
      if (_success) {
        $11 = $12;
        $3 = $11;
        break;
      }
      // NOP;
      int $13;
      var $14 = _c;
      var $15 = _cp;
      var $16 = _pos;
      var $17 = _c;
      var $18 = _cp;
      var $19 = _pos;
      var $20 = _predicate;
      var $21 = $1;
      _predicate = true;
      $1 = false;
      _matchString('\\');
      // NOP;
      _success = !_success;
      _c = $17;
      _cp = $18;
      _pos = $19;
      _predicate = $20;
      $1 = $21;
      if (_success) {
        var $24 = _c;
        var $25 = _cp;
        var $26 = _pos;
        var $27 = _predicate;
        var $28 = $1;
        _predicate = true;
        $1 = false;
        _parse$$EOL(404, false);
        // NOP;
        _success = !_success;
        _c = $24;
        _cp = $25;
        _pos = $26;
        _predicate = $27;
        $1 = $28;
        if (_success) {
          var $31 = _matchAny();
          if (_success) {
            $13 = $31;
          }
        }
      }
      if (!_success) {
        _c = $14;
        _cp = $15;
        _pos = $16;
      } else {
        $3 = $13;
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
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _parse$$RANGE_CHAR(408, $1);
      if (_success) {
        _matchString('-');
        if (_success) {
          var $10 = _parse$$RANGE_CHAR(410, $1);
          if (_success) {
            var s = $8;
            var e = $10;
            List<int> $$;
            $$ = [s, e];
            $4 = $$;
          }
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
      List<int> $11;
      var $12 = _parse$$RANGE_CHAR(412, $1);
      if (_success) {
        var c = $12;
        List<int> $$;
        $$ = [c, c];
        $11 = $$;
      }
      if (_success) {
        $3 = $11;
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
      var $7 = _cp;
      var $8 = _pos;
      _matchString('\\');
      if (_success) {
        const $10 = [45, 45, 92, 93, 110, 110, 114, 114, 116, 116];
        var $11 = _matchRanges($10);
        if (_success) {
          var c = $11;
          int $$;
          $$ = _escape(c);
          $5 = $$;
        }
      }
      if (!_success) {
        _c = $6;
        _cp = $7;
        _pos = $8;
      } else {
        $4 = $5;
        break;
      }
      // NOP;
      int $12;
      var $13 = _parse$$HEX_NUMBER(418, $1);
      if (_success) {
        $12 = $13;
        $4 = $12;
        break;
      }
      // NOP;
      int $14;
      var $15 = _c;
      var $16 = _cp;
      var $17 = _pos;
      var $18 = _c;
      var $19 = _cp;
      var $20 = _pos;
      var $21 = _predicate;
      var $22 = $1;
      _predicate = true;
      $1 = false;
      _matchString('\\');
      // NOP;
      _success = !_success;
      _c = $18;
      _cp = $19;
      _pos = $20;
      _predicate = $21;
      $1 = $22;
      if (_success) {
        var $25 = _c;
        var $26 = _cp;
        var $27 = _pos;
        var $28 = _predicate;
        var $29 = $1;
        _predicate = true;
        $1 = false;
        _parse$$EOL(423, false);
        // NOP;
        _success = !_success;
        _c = $25;
        _cp = $26;
        _pos = $27;
        _predicate = $28;
        $1 = $29;
        if (_success) {
          var $32 = _matchAny();
          if (_success) {
            $14 = $32;
          }
        }
      }
      if (!_success) {
        _c = $15;
        _cp = $16;
        _pos = $17;
      } else {
        $4 = $14;
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
      const $5 = [9, 9, 32, 32];
      var $6 = _matchRanges($5);
      if (_success) {
        $4 = $6;
        $3 = $4;
        break;
      }
      // NOP;
      dynamic $7;
      var $8 = _parse$$EOL(429, $1);
      if (_success) {
        $7 = $8;
        $3 = $7;
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
    if ($1) {
      $6 = [];
    }
    for (;;) {
      dynamic $7;
      for (;;) {
        dynamic $8;
        var $9 = _parse$$SPACE(435, $1);
        if (_success) {
          $8 = $9;
          $7 = $8;
          break;
        }
        // NOP;
        String $10;
        var $11 = _parse$$COMMENT(437, $1);
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
      if ($1) {
        $6.add($7);
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
      var $6 = _cp;
      var $7 = _pos;
      _matchString('//');
      if (_success) {
        var $9 = _matchChar(39);
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
      const $11 = [32, 38, 40, 126];
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
