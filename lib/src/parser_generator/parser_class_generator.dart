// @dart = 2.10
part of '../../parser_generator.dart';

class ParserClassGenerator {
  static const _methodParse = '''
    _source = source;
    _reset();
    final result = {{PARSE}}();
        if (!ok) {
      _buildError();
    }

    return result;
''';

  static const _methodBuildError = r"""
    final names = <String>[];
    final ends = <int>[];
    var failEnd = 0;
    for (var i = 0; i < _failures.length; i += 2) {
      final name = _failures[i] as String;
      var end = _failures[i + 1] as int;
      if (end == -1) {
        end = _failStart;
      }

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
""";

  static const _methodFail = '''
    if (_pos < _failStart) {
      return;
    }

    if (_failStart < _pos) {
      _failStart = _pos;
      _failures = [];
    }

    _failures.add(name);
    _failures.add(_failPos);
''';

  static const _methodGetChar = '''
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
''';

  static const _methodMatchAny = '''
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
''';

  static const _methodMatchChar = '''
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
''';

  static const _methodMatchRange = '''
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
''';

  static const _methodMatchString = r'''  
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
''';

  static const _methodReset = '''
    error = null;
    _failPos = 0;
    _failStart = 0;
    _failures = [];
    _pos = 0;
    _ch = _getChar(0);
    ok = false;
''';

  final Grammar grammar;

  final String name;

  final ParserGeneratorOptions options;

  ParserClassGenerator(this.name, this.grammar, this.options);

  Class generate() {
    return _generate();
  }

  void _addClassAttributes(ClassBuilder b) {
    b.name = name;
  }

  void _addFields(ClassBuilder b) {
    b.fields.add(Field((b) {
      b.static = true;
      b.modifier = FieldModifier.constant;
      b.name = Members.eof;
      b.type = refer('int');
      b.assignment = literal(0x10ffff + 1).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.error;
      b.type = refer('FormatException?');
    }));    

    b.fields.add(Field((b) {
      b.name = Members.failStart;
      b.type = refer('int');
      b.assignment = literal(-1).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.failures;
      b.type = refer('List');
      b.assignment = literal([]).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.ok;
      b.type = refer('bool');
      b.assignment = literalFalse.code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.ch;
      b.type = refer('int');
      b.assignment = literal(0).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.failPos;
      b.type = refer('int');
      b.assignment = literal(-1).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.pos;
      b.type = refer('int');
      b.assignment = literal(0).code;
    }));

    b.fields.add(Field((b) {
      b.name = Members.source;
      b.type = refer('String');
      b.assignment = literalString('').code;
    }));
  }

  void _addMembers() {
    final members = grammar.members;
    if (members != null) {
      throw UnimplementedError(
          'The Dart code builder does not allow to add arbitrary code to classes');
    }
  }

  void _addMethod(ClassBuilder b, List<Method> methods, String name,
      Reference returns, Code body,
      {Map<String, Reference> parameters = const {},
      List<Reference> types = const []}) {
    final method = Method((b) {
      b.name = name;
      b.returns = returns;
      b.types.addAll(types);

      for (final key in parameters.keys) {
        b.requiredParameters.add(Parameter((b) {
          final type = parameters[key];
          b.name = key;
          b.type = type;
        }));
      }

      b.body = body;
    });

    methods.add(method);
  }

  void _addMethodParse(ClassBuilder b, List<Method> methods) {
    final start = grammar.start;
    final returnType = start.returnType ?? 'dynamic';
    final returns = refer(returnType + '?');
    final parameters = <String, Reference>{};
    parameters['source'] = refer('String');
    final code = <Code>[];
    code <<
        Code(_methodParse.replaceAll(
            '{{PARSE}}', Utils.getRuleIdentifier(start)));
    _addMethod(b, methods, 'parse', returns, Block.of(code),
        parameters: parameters);
  }

  void _addMethods(ClassBuilder b, List<Method> methods) {
    var returns = refer('void');
    var name = '_buildError';
    var body = Code(_methodBuildError);
    var parameters = <String, Reference>{};
    var types = <Reference>[];
    _addMethod(b, methods, name, returns, body);

    returns = refer('void');
    name = Members.fail;
    body = Code(_methodFail);
    parameters = <String, Reference>{};
    parameters['name'] = refer('String');
    _addMethod(b, methods, name, returns, body, parameters: parameters);

    returns = refer('int');
    name = '_getChar';
    parameters = <String, Reference>{};
    parameters['pos'] = refer('int');
    body = Code(_methodGetChar);
    _addMethod(b, methods, name, returns, body, parameters: parameters);

    returns = refer('int?');
    name = Members.matchAny;
    body = Code(_methodMatchAny);
    _addMethod(b, methods, name, returns, body);

    returns = refer('T?');
    name = Members.matchChar;
    body = Code(_methodMatchChar);
    parameters = {};
    parameters['ch'] = refer('int');
    parameters['result'] = refer('T?');
    types = [];
    types.add(refer('T'));
    _addMethod(b, methods, name, returns, body,
        parameters: parameters, types: types);

    returns = refer('int?');
    name = Members.matchRange;
    body = Code(_methodMatchRange);
    parameters = {};
    parameters['ranges'] = refer('List<int>');
    _addMethod(b, methods, name, returns, body, parameters: parameters);

    returns = refer('String?');
    name = Members.matchString;
    body = Code(_methodMatchString);
    parameters = {};
    parameters['text'] = refer('String');
    _addMethod(b, methods, name, returns, body, parameters: parameters);

    returns = refer('void');
    name = '_reset';
    body = Code(_methodReset);
    _addMethod(b, methods, name, returns, body);
  }

  void _addRule(ClassBuilder b, List<Method> methods, ProductionRule rule) {
    final method = Method((b) {
      final expression = rule.expression;
      final returnType = rule.returnType ?? expression.returnType;
      b.name = Utils.getRuleIdentifier(rule);
      b.returns = refer(returnType + '?');
      final allocator = VariableAllocator('\$');
      final code = <Code>[];
      if (rule.kind == ProductionRuleKind.terminal) {
        code << assign(Members.failPos, literal(-1));
      }

      final generator = ExpressionsGenerator(allocator: allocator, code: code);
      final variable = allocator.alloc();
      code << declareVariable(refer(returnType + '?'), variable);
      generator.variable = variable;
      expression.accept(generator);
      b.body = Block.of(code);
    });

    methods.add(method);
  }

  void _addRules(ClassBuilder b, List<Method> methods) {
    for (final rule in grammar.rules) {
      _addRule(b, methods, rule);
    }
  }

  Class _generate() {
    return Class((b) {
      final methods = <Method>[];
      _addClassAttributes(b);
      _addFields(b);
      _addMethodParse(b, methods);
      _addRules(b, methods);
      _addMethods(b, methods);
      _addMembers();
      b.methods.addAll(methods);
    });
  }
}
