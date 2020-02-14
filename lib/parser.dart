class Parser {
  static const int _op_action = 0;

  static const int _op_call = _op_action + 1;

  static const int _op_capture_begin = _op_call + 1;

  static const int _op_capture_end = _op_capture_begin + 1;

  static const int _op_debug = _op_capture_end + 1;

  static const int _op_exit = _op_debug + 1;

  static const int _op_je = _op_exit + 1;

  static const int _op_jmp = _op_je + 1;

  static const int _op_jne = _op_jmp + 1;

  static const int _op_match_any_char = _op_jne + 1;

  static const int _op_match_ranges = _op_match_any_char + 1;

  static const int _op_match_string = _op_match_ranges + 1;

  static const int _op_nop = _op_match_string + 1;

  static const int _op_predicate_begin = _op_nop + 1;

  static const int _op_predicate_end = _op_predicate_begin + 1;

  static const int _op_productive_set = _op_predicate_end + 1;

  static const int _op_repetition_add = _op_productive_set + 1;

  static const int _op_repetition_array = _op_repetition_add + 1;

  static const int _op_repetition_begin = _op_repetition_array + 1;

  static const int _op_repetition_end = _op_repetition_begin + 1;

  static const int _op_result_assign = _op_repetition_end + 1;

  static const int _op_result_load = _op_result_assign + 1;

  static const int _op_result_store = _op_result_load + 1;

  static const int _op_return = _op_result_store + 1;

  static const int _op_rule_begin = _op_return + 1;

  static const int _op_rule_end = _op_rule_begin + 1;

  static const int _op_sequence_begin = _op_rule_end + 1;

  static const int _op_sequence_end = _op_sequence_begin + 1;

  static const int _op_sequence_fail = _op_sequence_end + 1;

  static const int _op_success_invert = _op_sequence_fail + 1;

  static const int _op_success_set = _op_success_invert + 1;

  static const int _op_value_store = _op_success_set + 1;

  static const _eof = 0x110000;

  static const _listTypes = <List>[];

  static List<String> _comments;

  static List<List> _operations;

  List<ParserError> errors = <ParserError>[];

  final List<String> opNames = const [
    'action',
    'call',
    'capture_begin',
    'capture_end',
    'debug',
    'exit',
    'je',
    'jmp',
    'jne',
    'match_any_char',
    'match_ranges',
    'match_string',
    'nop',
    'predicate_begin',
    'predicate_end',
    'productive_set',
    'repetition_add',
    'repetition_array',
    'repetition_begin',
    'repetition_end',
    'result_assign',
    'result_load',
    'result_store',
    'return',
    'rule_begin',
    'rule_end',
    'sequence_begin',
    'sequence_end',
    'sequence_fail',
    'success_invert',
    'success_set',
    'value_store',
  ];

  bool success;

  int _ch;

  int _chPos;

  List<String> _expected;

  int _expectedCount;

  int _failurePos;

  String _input;

  int _ip = 0;

  int _length;

  int _pos;

  bool _productive;

  dynamic _result;

  dynamic _r0;

  dynamic _r1;

  List _rrl;

  int _rvp;

  int _sp;

  List _stack;

  bool _steppingMode = false;

  bool _terminated = true;

  String _token;

  int _tokenStart;

  List<String> get comments => _comments;

  List<List> get operations => _operations;

  dynamic get result => _result;

  String disassemble() {
    final labels = findLabels();
    final length = _operations.length;
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      final operation = _operations[i];
      _writeOperation(sb, i, operation, labels);
      sb.writeln();
    }

    return sb.toString();
  }

  Map<int, String> findLabels() {
    final labels = <int, String>{};
    final length = _operations.length;
    for (var i = 0; i < length; i++) {
      final operation = _operations[i];
      final opCode = operation[0] as int;
      final name = getOpName(opCode);
      switch (name) {
        case 'je':
        case 'jmp':
        case 'jne':
          final address = operation[1] as int;
          labels[address] = null;
          break;
        case 'call':
          final address = operation[1] as int;
          final symbol = operation[2] as String;
          labels[address] = symbol;
          break;
      }
    }

    return labels;
  }

  String getOpName(int opCode) {
    String name;
    if (opCode < opNames.length) {
      name = opNames[opCode];
    } else {
      name = 'unknown ${opCode}';
    }

    return name;
  }

  dynamic parse(String text, {bool steppingMode = false}) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }

    if (steppingMode == null) {
      throw ArgumentError.notNull('steppingMode');
    }

    if (_steppingMode) {
      throw StateError('Unable to parse in stepping mode');
    }

    reset();
    _input = text;
    _length = _input.length;
    _ch = null;
    if (steppingMode) {
      _steppingMode = true;
      return null;
    }

    _parse();
    return _finalize();
  }

  void reset() {
    _steppingMode = false;
    _chPos = -1;
    _expected = <String>[];
    _expectedCount = 0;
    _failurePos = -1;
    _ip = 0;
    _pos = 0;
    _productive = true;
    _r0 = null;
    _r1 = null;
    _rrl = null;
    _rvp = 0;
    _stack = [];
    _stack.length = 1000;
    _sp = 0;
    _token = null;
    _tokenStart = -1;
    success = false;
    _terminated = false;
    errors = <ParserError>[];
  }

  SteppingResult step() {
    if (!_steppingMode) {
      throw StateError('Unable to step not in debug mode');
    }

    if (_terminated) {
      throw StateError('Unable to step terminated parser');
    }

    var exception;
    StackTrace stackTrace;
    try {
      _parse();
    } catch (e, s) {
      exception = e;
      stackTrace = s;
    }

    var result = _result;
    if (_terminated) {
      result = _finalize();
      _steppingMode = false;
    }

    return SteppingResult(
        exception: exception,
        ip: _ip,
        position: _pos,
        result: result,
        stackTrace: stackTrace,
        success: success,
        terminated: _terminated);
  }

  List<ParserError> _buildErrors() {
    if (success) {
      return <ParserError>[];
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
      if (position < _length) {
        return "'${escape(_input.codeUnitAt(position))}'";
      }

      return 'end of file';
    }

    final errors = <ParserError>[];
    if (_expectedCount > 0) {
      final expected = _expected.take(_expectedCount);
      final tokens = Set<String>.from(expected).toList();
      tokens.sort((e1, e2) => e1.compareTo(e2));
      final sb = StringBuffer();
      sb.write('Expected ');
      sb.write(tokens.join(', '));
      sb.write(' but found ');
      sb.write(getc(_failurePos));
      final message = sb.toString();
      final error = ParserError(_failurePos, _failurePos, message);
      errors.add(error);
    } else if (_failurePos >= 0) {
      final sb = StringBuffer();
      sb.write('Unexpected character ');
      sb.write(getc(_failurePos));
      final message = sb.toString();
      final error = ParserError(_failurePos, _failurePos, message);
      errors.add(error);
    }

    if (errors.isEmpty) {
      final error = ParserError(0, 0, 'Unknown error');
      errors.add(error);
    }

    return errors;
  }

  dynamic _finalize() {
    if (_sp != 0) {
      throw StateError('Internal error');
    }

    if (!success) {
      errors = _buildErrors();
    }

    _expected = null;
    _input = null;
    _stack = null;
    final result = _result;
    _result = null;
    return result;
  }

  void _parse() {
    while (true) {
      final operation = _operations[_ip];
      final opCode = operation[0] as int;
      while (true) {
        if (opCode < 16) {
          if (opCode < 8) {
            if (opCode < 4) {
              if (opCode < 2) {
                if (opCode == 1) {
                  // _op_call 1
                  if (_sp == _stack.length) {
                    _realloc(_stack, 1);
                  }

                  _stack[_sp++] = _ip + 1;
                  _ip = operation[1] as int;
                  break;
                } else if (opCode == 0) {
                  // _op_action 0
                  final id = operation[1] as int;
                  // {{ACTIONS}}
                  _ip++;
                  break;
                }
              } else if (opCode == 2) {
                // _op_capture_begin 2
                if (_sp + 2 >= _stack.length) {
                  _realloc(_stack, 2);
                }

                _sp += 2;
                _stack[_sp - 1] = _pos;
                _stack[_sp - 2] = _productive;
                _productive = false;
                _ip++;
                break;
              } else if (opCode == 3) {
                // _op_capture_end 3
                final productive = _stack[_sp - 2] as bool;
                if (success && productive) {
                  final start = _stack[_sp - 1] as int;
                  // TODO: Test
                  _result = _input.substring(start, _pos);
                } else {
                  _result = null;
                }

                _sp -= 2;
                _ip++;
                break;
              }
            } else if (opCode < 6) {
              if (opCode == 5) {
                // _op_exit 5
                _terminated = true;
                return;
              } else if (opCode == 4) {
                // _op_debug 4
                // TODO: Remove
                _ip++;
                break;
              }
            } else if (opCode == 6) {
              // _op_je 6
              if (success == true) {
                _ip = operation[1] as int;
              } else {
                _ip++;
              }

              break;
            } else if (opCode == 7) {
              // _op_jmp 7
              _ip = operation[1] as int;
              break;
            }
          } else if (opCode < 12) {
            if (opCode < 10) {
              if (opCode == 9) {
                // _op_match_any_char 9
                if (true) {
                  _ch = _eof;
                  var pos = _pos;
                  if (pos < _length) {
                    final leading = _input.codeUnitAt(pos++);
                    if ((leading & 0xFC00) == 0xD800 && pos < _length) {
                      final trailing = _input.codeUnitAt(pos);
                      if ((trailing & 0xFC00) == 0xDC00) {
                        _ch = 0x10000 +
                            ((leading & 0x3FF) << 10) +
                            (trailing & 0x3FF);
                        pos++;
                      } else {
                        _ch = leading;
                      }
                    } else {
                      _ch = leading;
                    }
                  } else {
                    _ch = _eof;
                  }
                }

                if (_ch != _eof) {
                  _result = _ch;
                  _pos += _ch < 0xffff ? 1 : 2;
                  _ch = null;
                  success = true;
                } else {
                  if (_failurePos < _pos) {
                    _expectedCount = 0;
                    _failurePos = _pos;
                  }

                  success = false;
                }

                _ip++;
                break;
              } else if (opCode == 8) {
                // _op_jne 8
                if (success == false) {
                  _ip = operation[1] as int;
                } else {
                  _ip++;
                }

                break;
              }
            } else if (opCode == 10) {
              // _op_match_ranges 10
              final ranges = operation[1] as List<int>;
              final length = ranges.length;
              if (true) {
                _ch = _eof;
                var pos = _pos;
                if (pos < _length) {
                  final leading = _input.codeUnitAt(pos++);
                  if ((leading & 0xFC00) == 0xD800 && _pos < _length) {
                    final trailing = _input.codeUnitAt(pos);
                    if ((trailing & 0xFC00) == 0xDC00) {
                      _ch = 0x10000 +
                          ((leading & 0x3FF) << 10) +
                          (trailing & 0x3FF);
                      pos++;
                    } else {
                      _ch = leading;
                    }
                  } else {
                    _ch = leading;
                  }
                } else {
                  _ch = _eof;
                }
              }

              //if (length > 16) {
              // Combine with binary search
              //}

              success = false;
              if (_ch != _eof) {
                for (var i = 0; i < length; i += 2) {
                  if (ranges[i] <= _ch) {
                    if (ranges[i + 1] >= _ch) {
                      _result = _ch;
                      _pos += _ch < 0xffff ? 1 : 2;
                      _ch = null;
                      success = true;
                      break;
                    }
                  } else {
                    break;
                  }
                }
              }

              if (!success) {
                if (_failurePos < _pos) {
                  _expectedCount = 0;
                  _failurePos = _pos;
                }
              }

              _ip++;
              break;
            } else if (opCode == 11) {
              // _op_match_string 11
              success = false;
              final text = operation[1] as String;
              final length = text.length;
              if (_pos + length <= _length) {
                var pos = _pos;
                var i = 0;
                for (; i < length; i++, pos++) {
                  if (text.codeUnitAt(i) != _input.codeUnitAt(pos)) {
                    break;
                  }
                }

                if (i == length) {
                  _pos += length;
                  _result = operation[1];
                  success = true;
                }
              }

              if (!success) {
                if (_failurePos < _pos) {
                  _expectedCount = 0;
                  _failurePos = _pos;
                }
              }

              _ip++;
              break;
            }
          } else if (opCode < 14) {
            if (opCode == 13) {
              // _op_predicate_begin 13
              if (_sp + 3 >= _stack.length) {
                _realloc(_stack, 3);
              }

              _sp += 3;
              _stack[_sp - 1] = _pos;
              _stack[_sp - 2] = _ch;
              _stack[_sp - 3] = _productive;
              _productive = false;
              _ip++;
              break;
            } else if (opCode == 12) {
              // _op_nop 12
              _ip++;
              break;
            }
          } else if (opCode == 14) {
            // _op_predicate_end 14
            _pos = _stack[_sp - 1] as int;
            _ch = _stack[_sp - 2] as int;
            _productive = _stack[_sp - 3] as bool;
            _result = null;
            _sp -= 3;
            _ip++;
            break;
          } else if (opCode == 15) {
            // _op_productive_set 15
            final productive = operation[1] as bool;
            _productive = productive;
            _ip++;
            break;
          }
        } else if (opCode < 24) {
          if (opCode < 20) {
            if (opCode < 18) {
              if (opCode == 17) {
                // _op_repetition_array 17
                if (_productive) {
                  final index = operation[1] as int;
                  final list = _listTypes[index];
                  _rrl = list.toList();
                }

                _ip++;
                break;
              } else if (opCode == 16) {
                // _op_repetition_add 16
                if (_productive) {
                  _rrl.add(_result);
                }

                _ip++;
                break;
              }
            } else if (opCode == 18) {
              // _op_repetition_begin 18
              if (_sp + 1 >= _stack.length) {
                _realloc(_stack, 1);
              }

              _sp += 1;
              _stack[_sp - 1] = _rrl;
              _rrl = null;
              _ip++;
              break;
            } else if (opCode == 19) {
              // _op_repetition_end 19
              _result = _rrl;
              _rrl = _stack[_sp - 1] as List;
              _sp -= 1;
              _ip++;
              break;
            }
          } else if (opCode < 22) {
            if (opCode == 21) {
              // _op_result_load 21
              final index = operation[1] as int;
              _result = _stack[_rvp - index];
              _ip++;
              break;
            } else if (opCode == 20) {
              // _op_result_assign 20
              _result = operation[1];
              _ip++;
              break;
            }
          } else if (opCode == 22) {
            // _op_result_store 22
            final index = operation[1] as int;
            _stack[_rvp - index] = _result;
            _ip++;
            break;
          } else if (opCode == 23) {
            // _op_return 23
            _ip = _stack[--_sp] as int;
            break;
          }
        } else if (opCode < 28) {
          if (opCode < 26) {
            if (opCode == 25) {
              // _op_rule_end 25
              if (operation[2] == 1) {
                if (!success) {
                  if (_tokenStart == _failurePos) {
                    if (_expected.length <= _expectedCount) {
                      _expected.length += 50;
                    }

                    _expected[_expectedCount++] = _token;
                  } else {
                    //
                  }
                }
              }

              if (operation[2] == 1) {
                _token = null;
              }

              _ip++;
              break;
            } else if (opCode == 24) {
              // _op_rule_begin 24
              if (operation[2] == 1) {
                _token = operation[1] as String;
                _tokenStart = _pos;
              }

              _ip++;
              break;
            }
          } else if (opCode == 26) {
            // _op_sequence_begin 26
            final count = operation[1] as int;
            final size = count + 5;
            if (_sp + size >= _stack.length) {
              _realloc(_stack, size);
            }

            _sp += size;
            _stack[_sp - 1] = _pos;
            _stack[_sp - 2] = _ch;
            _stack[_sp - 3] = _chPos;
            _stack[_sp - 4] = _productive;
            _stack[_sp - 5] = _rvp;
            _rvp = _sp - 6;
            _ip++;
            break;
          } else if (opCode == 27) {
            // _op_sequence_end 27
            _productive = _stack[_sp - 4] as bool;
            _rvp = _stack[_sp - 5] as int;
            final count = operation[1] as int;
            final size = count + 5;
            _sp -= size;
            _ip++;
            break;
          }
        } else if (opCode < 30) {
          if (opCode == 29) {
            // _op_success_invert 29
            success = !success;
            _ip++;
            break;
          } else if (opCode == 28) {
            // _op_sequence_fail 28
            _pos = _stack[_sp - 1] as int;
            _ch = _stack[_sp - 2] as int;
            _chPos = _stack[_sp - 3] as int;
            _ip++;
            break;
          }
        } else if (opCode == 30) {
          // _op_success_set 30
          success = true;
          _ip++;
          break;
        } else if (opCode == 31) {
          // _op_value_store 31
          final index = operation[1] as int;
          final value = operation[2];
          _stack[_rvp - index] = value;
          _ip++;
          break;
        }

        throw StateError('Invalid operation: ${operation}');
      }
      // ENCODER END

      if (_steppingMode) {
        return;
      }
    }
  }

  void _realloc(List stack, int n) {
    if (n < 1000) {
      n = 1000;
    }
    stack.length += n;
  }

  void _writeOperation(
      StringBuffer sb, int ip, List operation, Map<int, String> labels) {
    final opCode = operation[0] as int;
    final name = getOpName(opCode);
    if (labels.containsKey(ip)) {
      var symbol = labels[ip];
      symbol ??= '@${ip}';
      sb.write(symbol);
      sb.writeln(':');
    }

    sb.write('  ');
    sb.write(ip);
    sb.write(' ');
    sb.write(name);
    for (var n = 1; n < operation.length; n++) {
      final argument = operation[n];
      sb.write(' ');
      sb.write(argument);
    }
  }
}

class ParserError {
  final String message;

  final int position;

  final int start;

  ParserError(this.position, this.start, this.message);
}

class SteppingResult {
  final dynamic exception;
  final int ip;
  final int position;
  final dynamic result;
  final StackTrace stackTrace;
  final bool success;
  final bool terminated;

  SteppingResult(
      {this.exception,
      this.ip,
      this.position,
      this.result,
      this.stackTrace,
      this.success,
      this.terminated});
}
