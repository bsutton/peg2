part of '../../generators.dart';

class ParserClassGenerator {
  final Grammar grammar;

  final ParserGeneratorOptions options;

  ParserClassGenerator(this.grammar, this.options);

  void build(ContentBuilder builder, ContentBuilder methodBuilders) {
    final name = options.name + 'Parser';
    final classBuilder = ClassBuilder(name: name);
    builder.add(classBuilder);
    _buildParserFields(classBuilder);
    _buildParserMethods(classBuilder, grammar.rules[0]);
    classBuilder.add(methodBuilders);
  }

  void _buildParserFields(ContentBuilder builder) {
    final variables = [
      'static const _eof = 0x110000',
      'FormatException error',
      'int _c',
      'int _cp',
      'int _failed',
      'int _failurePos',
      'bool _hasMalformed',
      'String _input',
      'List<bool> _memoizable',
      'List<List<_Memo>> _memos',
      'var _mresult',
      'int _pos',
      'bool _predicate',
      'dynamic _result',
      'List<_State> _states',
      'int _statesPos',
      'bool _success',
      'List<String> _terminals',
      'int _terminalCount',
      'List<int> _trackCid',
      'List<int> _trackPos',
    ];

    for (final variable in variables) {
      builder.add(variable + ';');
      builder.add('');
    }
  }

  void _buildParserMethods(ContentBuilder builder, ProductionRule start) {
    const _methods = r'''
dynamic parse(String text) {
  if (text == null) {
    throw ArgumentError.notNull('text');
  }
  _input = text;
  _reset();
  final result = {{START}};
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

void _popState() {
  if (_statesPos <= 0) {
    throw StateError('Stack error');
  }

  final state = _states[_statesPos--];
  _c = state.c;
  _cp = state.cp;
  _pos = state.pos;
  _predicate = state.predicate;
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
  _cp = -1;  
  _failurePos = -1;
  _hasMalformed = false;
  _memoizable = [];
  _memoizable.length = {{EXPR_COUNT}};
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
  _trackCid.length = {{EXPR_COUNT}};
  _trackPos = [];
  _trackPos.length = {{EXPR_COUNT}};
}

''';

    final cid = start.id;
    String name;
    if (options.isPostfix()) {
      name = '_e${start.id}';
    } else {
      name = '_parse${start.name}';
    }

    var methods = _methods;
    methods = methods.replaceFirst('{{START}}', '$name($cid, true)');
    methods =
        methods.replaceAll('{{EXPR_COUNT}}', '${grammar.expressionCount}');
    final lineSplitter = LineSplitter();
    final lines = lineSplitter.convert(methods);
    builder.addAll(lines);
  }
}
