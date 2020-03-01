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
      'int _error',
      'List<String> _expected',
      'int _failure',
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

  final lastCid = _trackCid[id];
  final lastPos = _trackPos[id];
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
  _error = 0;
  _expected = [];
  _failure = -1;
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
