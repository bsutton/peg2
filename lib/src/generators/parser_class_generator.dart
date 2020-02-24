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
      'List<String> _failures',
      'int _fcount',
      'int _fposEnd',
      'int _fposMax',
      'int _fposStart',
      'List<int> _input',
      'List<bool> _memoizable',
      'List<List<_Memo>> _memos',
      'var _mresult',
      'int _pos',
      'bool _predicate',
      'dynamic _result',
      'bool _success',
      'String _text',
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
  _text = text;
  _input = _toRunes(text);
  _reset();  
  final result = {{START}};
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
  _memoizable.length = {{EXPR_COUNT}};
  _memos = [];
  _memos.length = _input.length + 1;
  _pos = 0;
  _predicate = false;  
  _trackCid = [];
  _trackCid.length = {{EXPR_COUNT}};
  _trackPos = [];
  _trackPos.length = {{EXPR_COUNT}};
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
