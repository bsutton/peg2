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

  Grammar _parseGrammar(int $0, bool $1) {
    Grammar $2;
    Grammar $3;
    Grammar $4;
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
      // NOP;
      var $11 = _parse_globals(5, $1);
      if (!_success) {
        _success = true;
        $11 = null;
      }
      if (_success) {
        // NOP;
        var $13 = _parse_members(7, $1);
        if (!_success) {
          _success = true;
          $13 = null;
        }
        if (_success) {
          List<ProductionRule> $14;
          if ($1) {
            $14 = [];
          }
          var $15 = false;
          for (;;) {
            var $16 = _parseDefinition(9, $1);
            if (!_success) {
              _success = $15;
              if (!_success) {
                $14 = null;
              }
              break;
            }
            if ($1) {
              $14.add($16);
            }
            $15 = true;
          }
          if (_success) {
            _parse_end_of_file(10, false);
            if (_success) {
              var g = $11;
              var m = $13;
              var d = $14;
              Grammar $$;
              $$ = Grammar(d, g, m);
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
      $4 = $5;
      if (_success) {
        $3 = $4;
        break;
      }
      ProductionRule $6;
      var $7 = _parseTerminalDefinition(15, $1);
      $6 = $7;
      if (_success) {
        $3 = $6;
        break;
      }
      ProductionRule $8;
      var $9 = _parseSubterminalDefinition(17, $1);
      $8 = $9;
      if (_success) {
        $3 = $8;
      }
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
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
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
        if (!_success) {
          _c = $14;
          _cp = $15;
          _pos = $16;
        }
      }
      if (_success) {
        $3 = $13;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  OrderedChoiceExpression _parseNonterminalExpression(int $0, bool $1) {
    OrderedChoiceExpression $2;
    OrderedChoiceExpression $3;
    OrderedChoiceExpression $4;
    var $5 = _c;
    var $6 = _cp;
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
        var $13 = _cp;
        var $14 = _pos;
        _parse_$Slash(36, false);
        if (_success) {
          var $16 = _parseNonterminalSequence(37, $1);
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
        var e = $8;
        var n = $9;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
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

  SequenceExpression _parseNonterminalSequence(int $0, bool $1) {
    SequenceExpression $2;
    SequenceExpression $3;
    SequenceExpression $4;
    var $5 = _c;
    var $6 = _cp;
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
      // NOP;
      var $12 = _parse_action(43, $1);
      if (!_success) {
        _success = true;
        $12 = null;
      }
      if (_success) {
        var e = $8;
        var a = $12;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
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

  Expression _parseNonterminalPrefix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    // NOP;
    var $9 = _parse_semantic_value(47, $1);
    if (!_success) {
      _success = true;
      $9 = null;
    }
    if (_success) {
      // NOP;
      String $11;
      for (;;) {
        String $12;
        var $13 = _parse_$Ampersand(51, $1);
        $12 = $13;
        if (_success) {
          $11 = $12;
          break;
        }
        String $14;
        var $15 = _parse_$ExclamationMark(53, $1);
        $14 = $15;
        if (_success) {
          $11 = $14;
        }
        break;
      }
      if (!_success) {
        _success = true;
        $11 = null;
      }
      if (_success) {
        var $16 = _parseNonterminalSuffix(54, $1);
        if (_success) {
          var s = $9;
          var p = $11;
          var e = $16;
          Expression $$;
          $$ = _prefix(p, e, s);
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

  Expression _parseNonterminalSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseNonterminalPrimary(57, $1);
    if (_success) {
      // NOP;
      String $10;
      for (;;) {
        String $11;
        var $12 = _parse_$QuestionMark(61, $1);
        $11 = $12;
        if (_success) {
          $10 = $11;
          break;
        }
        String $13;
        var $14 = _parse_$Asterisk(63, $1);
        $13 = $14;
        if (_success) {
          $10 = $13;
          break;
        }
        String $15;
        var $16 = _parse_$PlusSign(65, $1);
        $15 = $16;
        if (_success) {
          $10 = $15;
        }
        break;
      }
      if (!_success) {
        _success = true;
        $10 = null;
      }
      if (_success) {
        var e = $8;
        var s = $10;
        Expression $$;
        $$ = _suffix(s, e);
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
        if (!_success) {
          _c = $9;
          _cp = $10;
          _pos = $11;
        }
      }
      if (_success) {
        $3 = $8;
      }
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
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
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
        if (!_success) {
          _c = $14;
          _cp = $15;
          _pos = $16;
        }
      }
      if (_success) {
        $3 = $13;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  OrderedChoiceExpression _parseExpression(int $0, bool $1) {
    OrderedChoiceExpression $2;
    OrderedChoiceExpression $3;
    OrderedChoiceExpression $4;
    var $5 = _c;
    var $6 = _cp;
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
        var $13 = _cp;
        var $14 = _pos;
        _parse_$Slash(93, false);
        if (_success) {
          var $16 = _parseSequence(94, $1);
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
        var e = $8;
        var n = $9;
        OrderedChoiceExpression $$;
        $$ = OrderedChoiceExpression([e, ...n]);
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

  SequenceExpression _parseSequence(int $0, bool $1) {
    SequenceExpression $2;
    SequenceExpression $3;
    SequenceExpression $4;
    var $5 = _c;
    var $6 = _cp;
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
      // NOP;
      var $12 = _parse_action(100, $1);
      if (!_success) {
        _success = true;
        $12 = null;
      }
      if (_success) {
        var e = $8;
        var a = $12;
        SequenceExpression $$;
        $$ = SequenceExpression(e, a);
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

  Expression _parsePrefix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    // NOP;
    var $9 = _parse_semantic_value(104, $1);
    if (!_success) {
      _success = true;
      $9 = null;
    }
    if (_success) {
      // NOP;
      String $11;
      for (;;) {
        String $12;
        var $13 = _parse_$Ampersand(108, $1);
        $12 = $13;
        if (_success) {
          $11 = $12;
          break;
        }
        String $14;
        var $15 = _parse_$ExclamationMark(110, $1);
        $14 = $15;
        if (_success) {
          $11 = $14;
        }
        break;
      }
      if (!_success) {
        _success = true;
        $11 = null;
      }
      if (_success) {
        var $16 = _parseSuffix(111, $1);
        if (_success) {
          var s = $9;
          var p = $11;
          var e = $16;
          Expression $$;
          $$ = _prefix(p, e, s);
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

  Expression _parseSuffix(int $0, bool $1) {
    Expression $2;
    Expression $3;
    Expression $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parsePrimary(114, $1);
    if (_success) {
      // NOP;
      String $10;
      for (;;) {
        String $11;
        var $12 = _parse_$QuestionMark(118, $1);
        $11 = $12;
        if (_success) {
          $10 = $11;
          break;
        }
        String $13;
        var $14 = _parse_$Asterisk(120, $1);
        $13 = $14;
        if (_success) {
          $10 = $13;
          break;
        }
        String $15;
        var $16 = _parse_$PlusSign(122, $1);
        $15 = $16;
        if (_success) {
          $10 = $15;
        }
        break;
      }
      if (!_success) {
        _success = true;
        $10 = null;
      }
      if (_success) {
        var e = $8;
        var s = $10;
        Expression $$;
        $$ = _suffix(s, e);
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
        if (!_success) {
          _c = $7;
          _cp = $8;
          _pos = $9;
        }
      }
      if (_success) {
        $3 = $6;
        break;
      }
      Expression $13;
      var $14 = _parse_literal(131, $1);
      $13 = $14;
      if (_success) {
        $3 = $13;
        break;
      }
      Expression $15;
      var $16 = _parse_character_class(133, $1);
      $15 = $16;
      if (_success) {
        $3 = $15;
        break;
      }
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
        if (!_success) {
          _c = $20;
          _cp = $21;
          _pos = $22;
        }
      }
      if (_success) {
        $3 = $19;
      }
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
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
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
        if (!_success) {
          _c = $14;
          _cp = $15;
          _pos = $16;
        }
      }
      if (_success) {
        $3 = $13;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  String _parseType(int $0, bool $1) {
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parseTypeName(154, $1);
    if (_success) {
      // NOP;
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
        if (!_success) {
          _c = $12;
          _cp = $13;
          _pos = $14;
        }
      }
      $10 = $11;
      if (!_success) {
        _success = true;
        $10 = null;
      }
      if (_success) {
        var n = $8;
        var a = $10;
        String $$;
        $$ = n + (a == null ? '' : '<' + a.join(', ') + '>');
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
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
      String $11;
      var $12 = _parse_type_name(167, $1);
      $11 = $12;
      if (_success) {
        $3 = $11;
      }
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
        var t = $8;
        var n = $9;
        List<String> $$;
        $$ = [t, ...n];
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

  String _parse_non_terminal_name(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse$$IDENTIFIER(178, $1);
    if (_success) {
      _parse$$SPACING(179, false);
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
      _failure('\'non terminal name\'');
    }
    return $2;
  }

  String _parse_terminal_name(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
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
    var $16 = _matchChar(39);
    if (_success) {
      List $17;
      if ($1) {
        $17 = [];
      }
      var $18 = false;
      for (;;) {
        dynamic $19;
        dynamic $20;
        var $21 = _c;
        var $22 = _cp;
        var $23 = _pos;
        var $24 = _c;
        var $25 = _cp;
        var $26 = _pos;
        var $27 = _predicate;
        var $28 = $1;
        _predicate = true;
        $1 = false;
        _matchChar(39);
        var $30;
        _success = !_success;
        _c = $24;
        _cp = $25;
        _pos = $26;
        _predicate = $27;
        $1 = $28;
        if (_success) {
          _parse$$TERMINAL_CHAR(191, false);
          if (_success) {
            $20 = $30;
          } else {
            _c = $21;
            _cp = $22;
            _pos = $23;
          }
        }
        $19 = $20;
        if (!_success) {
          _success = $18;
          if (!_success) {
            $17 = null;
          }
          break;
        }
        if ($1) {
          $17.add($19);
        }
        $18 = true;
      }
      if (_success) {
        _matchChar(39);
        if (_success) {
          $12 = $16;
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
      _parse$$SPACING(193, false);
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
      _failure('\'terminal name\'');
    }
    return $2;
  }

  String _parse_sub_terminal_name(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
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
    var $16 = _matchChar(64);
    if (_success) {
      _parse$$IDENTIFIER(200, false);
      if (_success) {
        $12 = $16;
      } else {
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
      _parse$$SPACING(201, false);
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
      _failure('\'sub terminal name\'');
    }
    return $2;
  }

  String _parse_semantic_value(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _parse$$IDENTIFIER(204, $1);
    if (_success) {
      _matchString(':');
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
      _failure('\'semantic value\'');
    }
    return $2;
  }

  String _parse_type_name(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    String $8;
    var $9 = _pos;
    var $10 = $1;
    $1 = false;
    String $11;
    String $12;
    var $13 = _c;
    var $14 = _cp;
    var $15 = _pos;
    var $16 = _parse$$IDENTIFIER(211, $1);
    if (_success) {
      // NOP;
      var $18 = _matchChar(63);
      if (!_success) {
        _success = true;
        $18 = null;
      }
      if (_success) {
        $12 = $16;
      } else {
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
      _parse$$SPACING(214, false);
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
      _failure('\'type name\'');
    }
    return $2;
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
    // NOP;
    var $14 = _matchChar(95);
    if (!_success) {
      _success = true;
      $14 = null;
    }
    if (_success) {
      _parse$$IDENTIFIER(222, false);
      if (_success) {
        $9 = $14;
      } else {
        _c = $10;
        _cp = $11;
        _pos = $12;
      }
    }
    $8 = $9;
    if (_success) {
      $5 = _input.substring($6, _pos);
    }
    $1 = $7;
    $4 = $5;
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'library prefix\'');
    }
    return $2;
  }

  String _parse_$Semicolon(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString(';');
    if (_success) {
      _parse$$SPACING(226, false);
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
      _failure('\';\'');
    }
    return $2;
  }

  String _parse_action(int $0, bool $1) {
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
        var $15 = _parse$$ACTION_BODY(234, $1);
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      $13 = $14;
      $12 = $13;
      if (_success) {
        $9 = _input.substring($10, _pos);
      }
      $1 = $11;
      if (_success) {
        _matchString('}');
        if (_success) {
          _parse$$SPACING(236, false);
          if (_success) {
            $4 = $9;
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
      _failure('\'action\'');
    }
    return $2;
  }

  String _parse_$Ampersand(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('&');
    if (_success) {
      _parse$$SPACING(240, false);
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
      _failure('\'&\'');
    }
    return $2;
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
          } else {
            _c = $13;
            _cp = $14;
            _pos = $15;
          }
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
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'character class\'');
    }
    return $2;
  }

  String _parse_$RightParenthesis(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString(')');
    if (_success) {
      _parse$$SPACING(255, false);
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
      _failure('\')\'');
    }
    return $2;
  }

  String _parse_$Period(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('.');
    if (_success) {
      _parse$$SPACING(259, false);
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
      _failure('\'.\'');
    }
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
          _success = true;
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      $13 = $14;
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
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
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
    $4 = $5;
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'leading spaces\'');
    }
    return $2;
  }

  String _parse_$EqualSign(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('=');
    if (_success) {
      _parse$$SPACING(280, false);
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
      _failure('\'=\'');
    }
    return $2;
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
          _success = true;
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      $13 = $14;
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
      if (!_success) {
        _c = $5;
        _cp = $6;
        _pos = $7;
      }
    }
    $3 = $4;
    $2 = $3;
    if (!_success) {
      _failure('\'members\'');
    }
    return $2;
  }

  String _parse_$ExclamationMark(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('!');
    if (_success) {
      _parse$$SPACING(305, false);
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
      _failure('\'!\'');
    }
    return $2;
  }

  String _parse_$LeftParenthesis(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('(');
    if (_success) {
      _parse$$SPACING(309, false);
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
      _failure('\'(\'');
    }
    return $2;
  }

  String _parse_$PlusSign(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('+');
    if (_success) {
      _parse$$SPACING(313, false);
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
      _failure('\'+\'');
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
      _parse$$SPACING(317, false);
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

  String _parse_$QuestionMark(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('?');
    if (_success) {
      _parse$$SPACING(321, false);
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
      _failure('\'?\'');
    }
    return $2;
  }

  String _parse_$Slash(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('/');
    if (_success) {
      _parse$$SPACING(325, false);
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
      _failure('\'/\'');
    }
    return $2;
  }

  String _parse_$Asterisk(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('*');
    if (_success) {
      _parse$$SPACING(329, false);
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
      _failure('\'*\'');
    }
    return $2;
  }

  String _parse_$LessThanSign(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('<');
    if (_success) {
      _parse$$SPACING(333, false);
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
      _failure('\'<\'');
    }
    return $2;
  }

  String _parse_$GreaterThanSign(int $0, bool $1) {
    _failed = -1;
    String $2;
    String $3;
    String $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    var $8 = _matchString('>');
    if (_success) {
      _parse$$SPACING(337, false);
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
      _failure('\'>\'');
    }
    return $2;
  }

  dynamic _parse$$ACTION_BODY(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    for (;;) {
      String $4;
      var $5 = _c;
      var $6 = _cp;
      var $7 = _pos;
      var $8 = _matchString('{');
      if (_success) {
        List $9;
        if ($1) {
          $9 = [];
        }
        for (;;) {
          var $10 = _parse$$ACTION_BODY(342, false);
          if (!_success) {
            _success = true;
            break;
          }
          if ($1) {
            $9.add($10);
          }
        }
        if (_success) {
          _matchString('}');
          if (_success) {
            $4 = $8;
          }
        }
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
      dynamic $12;
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
      _matchString('}');
      var $22;
      _success = !_success;
      _c = $16;
      _cp = $17;
      _pos = $18;
      _predicate = $19;
      $1 = $20;
      if (_success) {
        _matchAny();
        if (_success) {
          $12 = $22;
        } else {
          _c = $13;
          _cp = $14;
          _pos = $15;
        }
      }
      if (_success) {
        $3 = $12;
      }
      break;
    }
    $2 = $3;
    return $2;
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
        // NOP;
        var $24 = _parse$$EOL(358, false);
        if (!_success) {
          _success = true;
          $24 = null;
        }
        if (_success) {
          $4 = $8;
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

  dynamic _parse$$EOL(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    for (;;) {
      String $4;
      var $5 = _matchString('\r\n');
      $4 = $5;
      if (_success) {
        $3 = $4;
        break;
      }
      int $6;
      const $7 = [10, 10, 13, 13];
      var $8 = _matchRanges($7);
      $6 = $8;
      if (_success) {
        $3 = $6;
      }
      break;
    }
    $2 = $3;
    return $2;
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

  int _parse$$HEX_NUMBER(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    var $5 = _c;
    var $6 = _cp;
    var $7 = _pos;
    _matchChar(92);
    if (_success) {
      _matchString('u');
      if (_success) {
        String $10;
        var $11 = _pos;
        var $12 = $1;
        $1 = false;
        List<int> $13;
        List<int> $14;
        List<int> $15;
        if ($1) {
          $15 = [];
        }
        var $16 = false;
        for (;;) {
          const $17 = [48, 57, 65, 70, 97, 102];
          var $18 = _matchRanges($17);
          if (!_success) {
            _success = $16;
            if (!_success) {
              $15 = null;
            }
            break;
          }
          if ($1) {
            $15.add($18);
          }
          $16 = true;
        }
        $14 = $15;
        $13 = $14;
        if (_success) {
          $10 = _input.substring($11, _pos);
        }
        $1 = $12;
        if (_success) {
          var d = $10;
          int $$;
          $$ = int.parse(d, radix: 16);
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

  String _parse$$IDENTIFIER(int $0, bool $1) {
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
    var $13 = _parse$$IDENT_START(383, $1);
    if (_success) {
      List<int> $14;
      if ($1) {
        $14 = [];
      }
      for (;;) {
        var $15 = _parse$$IDENT_CONT(385, false);
        if (!_success) {
          _success = true;
          break;
        }
        if ($1) {
          $14.add($15);
        }
      }
      if (_success) {
        $9 = $13;
      } else {
        _c = $10;
        _cp = $11;
        _pos = $12;
      }
    }
    $8 = $9;
    if (_success) {
      $5 = _input.substring($6, _pos);
    }
    $1 = $7;
    $4 = $5;
    $3 = $4;
    $2 = $3;
    return $2;
  }

  int _parse$$IDENT_CONT(int $0, bool $1) {
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _parse$$IDENT_START(388, $1);
      $4 = $5;
      if (_success) {
        $3 = $4;
        break;
      }
      int $6;
      const $7 = [48, 57, 95, 95];
      var $8 = _matchRanges($7);
      $6 = $8;
      if (_success) {
        $3 = $6;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  int _parse$$IDENT_START(int $0, bool $1) {
    int $2;
    int $3;
    int $4;
    const $5 = [65, 90, 97, 122];
    var $6 = _matchRanges($5);
    $4 = $6;
    $3 = $4;
    $2 = $3;
    return $2;
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
      int $11;
      var $12 = _parse$$HEX_NUMBER(399, $1);
      $11 = $12;
      if (_success) {
        $3 = $11;
        break;
      }
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
        if (!_success) {
          _c = $14;
          _cp = $15;
          _pos = $16;
        }
      }
      if (_success) {
        $3 = $13;
      }
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
        if (!_success) {
          _c = $5;
          _cp = $6;
          _pos = $7;
        }
      }
      if (_success) {
        $3 = $4;
        break;
      }
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
    int $2;
    int $3;
    for (;;) {
      int $4;
      var $5 = _c;
      var $6 = _cp;
      var $7 = _pos;
      _matchString('\\');
      if (_success) {
        const $9 = [45, 45, 92, 93, 110, 110, 114, 114, 116, 116];
        var $10 = _matchRanges($9);
        if (_success) {
          var c = $10;
          int $$;
          $$ = _escape(c);
          $4 = $$;
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
      int $11;
      var $12 = _parse$$HEX_NUMBER(418, $1);
      $11 = $12;
      if (_success) {
        $3 = $11;
        break;
      }
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
        _parse$$EOL(423, false);
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
        if (!_success) {
          _c = $14;
          _cp = $15;
          _pos = $16;
        }
      }
      if (_success) {
        $3 = $13;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  dynamic _parse$$SPACE(int $0, bool $1) {
    dynamic $2;
    dynamic $3;
    for (;;) {
      int $4;
      const $5 = [9, 9, 32, 32];
      var $6 = _matchRanges($5);
      $4 = $6;
      if (_success) {
        $3 = $4;
        break;
      }
      dynamic $7;
      var $8 = _parse$$EOL(429, $1);
      $7 = $8;
      if (_success) {
        $3 = $7;
      }
      break;
    }
    $2 = $3;
    return $2;
  }

  List _parse$$SPACING(int $0, bool $1) {
    List $2;
    List $3;
    List $4;
    List $5;
    if ($1) {
      $5 = [];
    }
    for (;;) {
      dynamic $6;
      for (;;) {
        dynamic $7;
        var $8 = _parse$$SPACE(435, $1);
        $7 = $8;
        if (_success) {
          $6 = $7;
          break;
        }
        String $9;
        var $10 = _parse$$COMMENT(437, $1);
        $9 = $10;
        if (_success) {
          $6 = $9;
        }
        break;
      }
      if (!_success) {
        _success = true;
        break;
      }
      if ($1) {
        $5.add($6);
      }
    }
    $4 = $5;
    $3 = $4;
    $2 = $3;
    return $2;
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
      const $11 = [32, 38, 40, 126];
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
}

// ignore_for_file: prefer_final_locals
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_local_variable
