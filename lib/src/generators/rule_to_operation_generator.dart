part of '../../generators.dart';

class RulesToOperationsBuilder extends ExpressionVisitor {
  Variable _c;

  Variable _cp;

  BlockOperation _block;

  Variable _failed;

  Variable _failure;

  int _lastVariableIndex;

  Variable _memoizable;

  Variable _memoize;

  Variable _memoized;

  Variable _mresult;

  bool _notProductive;

  ParserGeneratorOptions _options;

  Variable _pos;

  Variable _predicate;

  Variable _productive;

  Variable _result;

  Variable _success;

  Map<Expression, ProductionRule> _topExpressions;

  List<MethodOperation> build(Grammar grammar, ParserGeneratorOptions options) {
    if (grammar == null) {
      throw ArgumentError.notNull('grammar');
    }

    _c = Variable('_c');
    _cp = Variable('_cp');
    _failed = Variable('_failed');
    _failure = Variable('_failure');
    _memoizable = Variable('_memoizable');
    _memoize = Variable('_memoize');
    _memoized = Variable('_memoized');
    _mresult = Variable('_mresult');
    _notProductive = false;
    _options = options;
    _predicate = Variable('_predicate');
    _pos = Variable('_pos');
    _success = Variable('_success');
    _topExpressions = {};
    final rules = grammar.rules;
    for (var rule in rules) {
      _topExpressions[rule.expression] = rule;
    }

    final result = <MethodOperation>[];
    for (final rule in rules) {
      var skip = false;
      if (rule.callers.length == 1) {
        switch (rule.kind) {
          case ProductionRuleKind.Nonterminal:
            if (_options.inlineNonterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.Subterminal:
            if (_options.inlineSubterminals) {
              skip = true;
            }

            break;
          default:
        }
      }

      if (!skip) {
        final method = _buildRule(rule);
        result.add(method);
      }
    }

    return result;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final b = _block;
    final child = node.expression;
    _addNodeComment(b, node);
    final state = _saveVars(b, [
      _c,
      _cp,
      _pos,
      _predicate,
      _productive,
    ]);

    _addAssign(b, _varOp(_predicate), _constOp(true));
    _addAssign(b, _varOp(_productive), _constOp(false));
    child.accept(this);
    final result = _newVar(b, 'var');
    _restoreVars(b, state);
    _result = result;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final b = _block;
    _addNodeComment(b, node);
    final matchAny = _varOp(Variable('_matchAny'));
    final methodCall = _call(matchAny, []);
    final result = _newVar(b, 'var', methodCall);
    _result = result;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final b = _block;
    _addNodeComment(b, node);
    final result = _newVar(b, 'String');
    final start = _newVar(b, 'var', _varOp(_pos));
    final saved = _saveVars(b, [_productive]);
    _addAssign(b, _varOp(_productive), _constOp(false));
    node.expression.accept(this);
    _ifSuccess(b, (b) {
      final substring = Variable('substring');
      final methodCall =
          _call(_varOp(substring), [_varOp(start), _varOp(_pos)]);
      final input = Variable('_input');
      final member = MemberOperation(_varOp(input), methodCall);
      _addAssign(b, _varOp(result), member);
    });

    _restoreVars(b, saved);
    _result = result;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final b = _block;
    final ranges = <int>[];
    var simple = true;
    for (final range in node.ranges) {
      final start = range[0];
      final end = range[1];
      ranges.add(start);
      ranges.add(end);
      if (start != end) {
        simple = false;
      }
    }

    _addNodeComment(b, node);
    CallOperation methodCall;
    Variable result;
    if (simple && ranges.length == 2) {
      final matchChar = Variable('_matchChar');
      methodCall = _call(_varOp(matchChar), [_constOp(ranges[0])]);
      result = _newVar(b, 'var', methodCall);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(ConstantOperation(ranges[i]));
        elements.add(ConstantOperation(ranges[i + 1]));
      }

      final listOp = ListOperation(null, elements);
      final list = _newVar(b, 'const', listOp);
      final matchRanges = Variable('_matchRanges');
      methodCall = _call(_varOp(matchRanges), [_varOp(list)]);
      result = _newVar(b, 'var', methodCall);
    }

    _result = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final b = _block;
    _addNodeComment(b, node);
    final matchString = Variable('_matchString');
    final methodCall = _call(_varOp(matchString), [_constOp(node.text)]);
    final result = _newVar(b, 'var', methodCall);
    _result = result;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final b = _block;
    final rule = node.expression.rule;
    final name = Variable(_getRuleName(rule));
    final cid = node.id;
    _addNodeComment(b, node);
    if (_options.inlineNonterminals && rule.callers.length == 1) {
      final child = rule.expression;
      child.accept(this);
    } else {
      final productive = _notProductive ? _constOp(false) : _varOp(_productive);
      final methodCall = _call(_varOp(name), [_constOp(cid), productive]);
      final result = _newVar(b, 'var', methodCall);
      _result = result;
    }
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final b = _block;
    final child = node.expression;
    _addNodeComment(b, node);
    final state = _saveVars(b, [
      _c,
      _cp,
      _pos,
      _predicate,
      _productive,
    ]);

    _addAssign(b, _varOp(_predicate), _constOp(true));
    _addAssign(b, _varOp(_productive), _constOp(false));
    child.accept(this);
    _result = _newVar(b, 'var', null);
    _addAssign(
        b, _varOp(_success), _unary(OperationKind.not, _varOp(_success)));
    _restoreVars(b, state);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final b = _block;
    final returnType = node.returnType;
    _addNodeComment(b, node);
    final result = _newVar(b, returnType, null);
    _addCond(b, _varOp(_productive), (b) {
      _addAssign(b, _varOp(result), ListOperation(null, []));
    });

    final passed = _newVar(b, 'var', _constOp(false));
    _addLoop(b, (b) {
      _block = b;
      node.expression.accept(this);
      _ifNotSuccess(b, (b) {
        _addAssign(b, _varOp(_success), _varOp(passed));
        _ifNotSuccess(b, (b) {
          _addAssign(b, _varOp(result), _constOp(null));
        });

        _addBreak(b);
      });

      _addCond(b, _varOp(_productive), (b) {
        final add = Variable('add');
        final addCall = _call(_varOp(add), [_varOp(_result)]);
        _addMember(b, _varOp(result), addCall);
      });

      _addAssign(b, _varOp(passed), _constOp(true));
    });

    _result = result;
    _block = b;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final b = _block;
    final child = node.expression;
    _addNodeComment(b, node);
    child.accept(this);
    _addAssign(b, _varOp(_success), _constOp(true));
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final b = _block;
    final expressions = node.expressions;
    final returnType = node.returnType;
    _addNodeComment(b, node);
    final result = _newVar(b, returnType, null);
    if (expressions.length > 1) {
      _addLoop(b, (b) {
        _block = b;
        for (var i = 0; i < expressions.length; i++) {
          final child = expressions[i];
          child.accept(this);
          if (i < expressions.length - 1) {
            _ifSuccess(b, (b) {
              _addAssign(b, _varOp(result), _varOp(_result));
              _addBreak(b);
            });
          } else {
            _ifSuccess(b, (b) {
              _addAssign(b, _varOp(result), _varOp(_result));
            });

            _addBreak(b);
          }
        }
      });
    } else {
      final child = expressions[0];
      child.accept(this);
      _addAssign(b, _varOp(result), _varOp(_result));
    }

    _result = result;
    _block = b;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final b = _block;
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final returnType = node.returnType;
    final variables = <Expression, Variable>{};
    final varCount = expressions.where((e) => e.variable != null).length;
    _addNodeComment(b, node);
    final result = _newVar(b, returnType, null);
    void Function(BlockOperation) onSuccess;
    void Function(BlockOperation) onFailure;
    final optionalCount = expressions.where((e) => e.isOptional).length;
    final allOptional = expressions.length == optionalCount;
    var hasSavedState = !allOptional;
    if (expressions.length == 1) {
      hasSavedState = false;
    }

    Map<Variable, Variable> savedState;
    if (hasSavedState) {
      savedState = _saveVars(b, [_c, _cp, _pos]);
    }

    final results = <Expression, Variable>{};
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (i == 0 && varCount == 0) {
        _notProductive = false;
      } else {
        if (child.variable == null) {
          _notProductive = true;
        } else {
          _notProductive = false;
        }
      }

      void onExpression(BlockOperation b) {
        _block = b;
        child.accept(this);
        results[child] = _result;
        if (child.variable != null) {
          variables[child] = _result;
        }
      }

      if (i == 0) {
        onExpression(_block);
      } else {
        _ifSuccess(_block, onExpression);
      }
    }

    if (hasSavedState) {
      onFailure = (b) {
        _restoreVars(b, savedState);
      };
    }

    if (hasAction) {
      onSuccess = (b) {
        _buildAction(b, node, result, variables);
      };
    } else {
      if (variables.isEmpty) {
        onSuccess = (b) {
          final variable = results.values.first;
          _addAssign(b, _varOp(result), _varOp(variable));
        };
      } else if (variables.length == 1) {
        onSuccess = (b) {
          final expression = variables.keys.first;
          final variable = results[expression];
          _addAssign(b, _varOp(result), _varOp(variable));
        };
      } else {
        onSuccess = (b) {
          final list =
              ListOperation(null, variables.values.map(_varOp).toList());
          _addAssign(b, _varOp(result), list);
        };
      }
    }

    _ifSuccess(_block, onSuccess);
    if (onFailure != null) {
      _ifNotSuccess(b, onFailure);
    }

    _block = b;
    _result = result;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final b = _block;
    final rule = node.expression.rule;
    final name = Variable(_getRuleName(rule));
    final cid = node.id;
    _addNodeComment(b, node);
    if (_options.inlineSubterminals && rule.callers.length == 1) {
      final child = rule.expression;
      child.accept(this);
    } else {
      final productive = _notProductive ? _constOp(false) : _varOp(_productive);
      final methodCall = _call(_varOp(name), [_constOp(cid), productive]);
      final result = _newVar(b, 'var', methodCall);
      _result = result;
    }
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final b = _block;
    final rule = node.expression.rule;
    final name = Variable(_getRuleName(rule));
    final cid = node.id;
    _addNodeComment(b, node);
    final productive = _notProductive ? _constOp(false) : _varOp(_productive);
    final methodCall = _call(_varOp(name), [_constOp(cid), productive]);
    final result = _newVar(b, 'var', methodCall);
    _result = result;
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final b = _block;
    final returnType = node.returnType;
    _addNodeComment(b, node);
    final result = _newVar(b, returnType, null);
    _addCond(b, _varOp(_productive), (b) {
      _addAssign(b, _varOp(result), ListOperation(null, []));
    });

    _addLoop(b, (b) {
      _block = b;
      node.expression.accept(this);
      _ifNotSuccess(b, _addBreak);
      _addCond(b, _varOp(_productive), (b) {
        final add = Variable('add');
        final addCall = _call(_varOp(add), [_varOp(_result)]);
        _addMember(b, _varOp(result), addCall);
      });
    });

    _addAssign(b, _varOp(_success), _constOp(true));
    _result = result;
    _block = b;
  }

  void _addAssign(BlockOperation b, Operation left, Operation right) {
    final operation = BinaryOperation(left, OperationKind.assign, right);
    b.operations.add(operation);
  }

  void _addBreak(BlockOperation b) {
    final op = BreakOperation();
    b.operations.add(op);
  }

  ConditionalOperation _addCond(BlockOperation block, Operation test,
      void Function(BlockOperation) ifTrue,
      [void Function(BlockOperation) ifFalse]) {
    final bTrue = BlockOperation();
    BlockOperation bFalse;
    if (ifFalse != null) {
      bFalse = BlockOperation();
    }

    final op = ConditionalOperation(test, bTrue, bFalse);
    block.operations.add(op);
    ifTrue(bTrue);
    if (ifFalse != null) {
      ifFalse(bFalse);
    }

    return op;
  }

  ConditionalOperation _addIf(
      BlockOperation block, Operation test, void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    final bTrue = BlockOperation();
    BlockOperation bFalse;
    if (fFalse != null) {
      bFalse = BlockOperation();
    }

    final op = ConditionalOperation(test, bTrue, bFalse);
    block.operations.add(op);
    fTrue(bTrue);
    if (fFalse != null) {
      fFalse(bFalse);
    }

    return op;
  }

  LoopOperation _addLoop(
      BlockOperation block, void Function(BlockOperation) f) {
    final body = BlockOperation();
    final op = LoopOperation(body);
    block.operations.add(op);
    if (f != null) {
      f(op.body);
    }

    return op;
  }

  void _addMember(BlockOperation b, Operation member, Operation operation) {
    final op = MemberOperation(member, operation);
    b.operations.add(op);
  }

  MethodOperation _addMethod(String type, String name,
      List<ParameterOperation> params, void Function(BlockOperation) f) {
    final body = BlockOperation();
    final op = MethodOperation(type, name, params, body);
    f(body);
    return op;
  }

  void _addNodeComment(BlockOperation block, Expression node) {
    //builder.add('// $node');
  }

  void _addOp(BlockOperation block, Operation operation) {
    block.operations.add(operation);
  }

  void _addReturn(BlockOperation b, Operation operation) {
    final op = ReturnOperation(operation);
    b.operations.add(op);
  }

  Variable _allocVar() {
    final result = Variable('\$${_lastVariableIndex++}');
    return result;
  }

  void _buildAction(BlockOperation block, SequenceExpression node,
      Variable result, Map<Expression, Variable> variables) {
    for (final expression in variables.keys) {
      final variable = Variable(expression.variable);
      final parameter =
          ParameterOperation('var', variable, _varOp(variables[expression]));
      block.operations.add(parameter);
    }

    final $$ = Variable('\$\$');
    final returnType = node.returnType;
    final parameter = ParameterOperation(returnType, $$);
    block.operations.add(parameter);
    final code = <String>[];
    final lineSplitter = LineSplitter();
    var lines = lineSplitter.convert(node.actionSource);
    if (lines.length == 1) {
      final line = lines[0];
      code.add(line.trim());
    } else {
      final temp = <String>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isNotEmpty) {
          temp.add(line);
        }
      }

      lines = temp;
      int indent;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        var j = 0;
        for (; j < line.length; j++) {
          final c = line.codeUnitAt(j);
          if (c != 32) {
            break;
          }
        }

        if (indent == null) {
          indent = j;
        } else if (indent > j) {
          indent = j;
        }
      }

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        code.add(line.substring(indent));
      }
    }

    final action = ActionOperation(variables.values.map(_varOp).toList(), code);
    block.operations.add(action);
    _addAssign(block, _varOp(result), _varOp($$));
  }

  MethodOperation _buildRule(ProductionRule rule) {
    _lastVariableIndex = 0;
    final cid = _allocVar();
    final expressionId = rule.expression.id;
    _productive = _allocVar();
    final name = _getRuleName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', cid));
    params.add(ParameterOperation('bool', _productive));
    var returnType = rule.returnType;
    returnType ??= rule.expression.returnType;
    Variable start;
    final result = _addMethod(returnType, name, params, (b) {
      _block = b;
      if (_options.memoize && rule.callers.length > 1) {
        final memoizedCall = CallOperation(
            _varOp(_memoized), [_constOp(expressionId), _varOp(cid)]);
        _addIf(b, memoizedCall, (b) {
          final convert = UnaryOperation(
              OperationKind.convert, _varOp(_mresult), returnType);
          _addReturn(b, convert);
        });

        start = _newVar(b, 'var', _varOp(_pos));
      }

      if (rule.kind == ProductionRuleKind.Terminal) {
        _addAssign(b, _varOp(_failed), _constOp(-1));
      }

      final result = _newVar(b, returnType, null);
      final expression = rule.expression;
      expression.accept(this);
      _addAssign(b, _varOp(result), _varOp(_result));
      if (rule.kind == ProductionRuleKind.Terminal) {
        _ifNotSuccess(b, (b) {
          final failureCall = _call(_varOp(_failure), [_constOp(rule.name)]);
          _addOp(b, failureCall);
        });
      }

      if (_options.memoize && rule.callers.length > 1) {
        final listAccess =
            ListAccessOperation(_varOp(_memoizable), _varOp(cid));
        final test =
            BinaryOperation(listAccess, OperationKind.equal, _constOp(true));
        _addIf(b, test, (b) {
          final memoizeCall = _call(_varOp(_memoize),
              [_constOp(expressionId), _varOp(start), _varOp(result)]);
          _addOp(b, memoizeCall);
        });
      }

      _addReturn(b, _varOp(result));
    });

    _productive = null;
    return result;
  }

  CallOperation _call(Operation op, List<Operation> args) {
    return CallOperation(op, args);
  }

  ConstantOperation<T> _constOp<T>(T value) {
    return ConstantOperation(value);
  }

  String _getRuleName(ProductionRule rule) {
    var name = rule.name;
    switch (rule.kind) {
      case ProductionRuleKind.Nonterminal:
        break;
      case ProductionRuleKind.Terminal:
        name = _getTerminalName(name, rule.id);
        break;
      case ProductionRuleKind.Subterminal:
        name = '\$\$' + name.substring(1);
    }

    final result = '_parse$name';
    return result;
  }

  String _getTerminalName(String name, int id) {
    name = name.substring(1, name.length - 1);
    const ascii00_31 = [
      'NUL',
      'SOH',
      'STX',
      'EOT',
      'EOT',
      'ENQ',
      'ACK',
      'BEL',
      'BS',
      'HT',
      'LF',
      'VT',
      'FF',
      'CR',
      'SO',
      'SI',
      'DLE',
      'DC1',
      'DC2',
      'DC3',
      'DC4',
      'NAK',
      'SYN',
      'ETB',
      'CAN',
      'EM',
      'SUB',
      'ESC',
      'FS',
      'GS',
      'RS',
      'US',
    ];

    const ascii32_47 = [
      'ExclamationMark',
      'DoubleQuotationMark',
      'NumberSign',
      'DollarSign',
      'PercentSign',
      'Ampersand',
      'Apostrophe',
      'LeftParenthesis',
      'RightParenthesis',
      'Asterisk',
      'PlusSign',
      'Comma',
      'MinusSign',
      'Period',
      'Slash',
    ];

    const ascii58_64 = [
      'Colon',
      'Semicolon',
      'LessThanSign',
      'EqualSign',
      'GreaterThanSign',
      'QuestionMark',
      'CommercialAtSign',
    ];

    const ascii91_96 = [
      'LeftSquareBracket',
      'Backslash',
      'RightSquareBracket',
      'SpacingCircumflexAccent',
      'SpacingUnderscore',
      'SpacingGraveAccent',
    ];

    const ascii123_127 = [
      'LeftBrace',
      'VerticalBar',
      'RightBrace',
      'TildeAccent',
      'Delete',
    ];

    final sb = StringBuffer();
    sb.write('_');
    var success = true;
    for (var i = 0; i < name.length; i++) {
      final c = name.codeUnitAt(i);
      if (c > 127) {
        success = false;
        break;
      }

      if (c >= 48 && c <= 57 || c >= 65 && c <= 90 || c >= 97 && c <= 122) {
        sb.write(name[i]);
      } else if (c == 32) {
        sb.write('_');
      } else if (c >= 0 && c <= 31) {
        sb.write('\$');
        sb.write(ascii00_31[c]);
      } else if (c >= 33 && c <= 47) {
        sb.write('\$');
        sb.write(ascii32_47[c - 33]);
      } else if (c >= 58 && c <= 64) {
        sb.write('\$');
        sb.write(ascii58_64[c - 58]);
      } else if (c >= 91 && c <= 96) {
        sb.write('\$');
        sb.write(ascii91_96[c - 91]);
      } else if (c >= 123 && c <= 127) {
        sb.write('\$');
        sb.write(ascii123_127[c - 123]);
      }
    }

    final result = sb.toString();
    if (!success || result.length > 32) {
      return '\$Terminal$id';
    }

    return result;
  }

  ConditionalOperation _ifNotSuccess(
      BlockOperation block, void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    final test = UnaryOperation(OperationKind.not, _varOp(_success));
    return _addIf(block, test, fTrue, fFalse);
  }

  ConditionalOperation _ifSuccess(
      BlockOperation block, void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    final test = _success;
    return _addIf(block, _varOp(test), fTrue, fFalse);
  }

  Variable _newVar(BlockOperation b, String type, [Operation value]) {
    final variable = _allocVar();
    final parameter = ParameterOperation(type, variable, value);
    b.operations.add(parameter);
    return variable;
  }

  void _restoreVars(BlockOperation block, Map<Variable, Variable> variables) {
    for (final key in variables.keys) {
      _addAssign(block, _varOp(variables[key]), _varOp(key));
    }
  }

  Map<Variable, Variable> _saveVars(
      BlockOperation block, List<Variable> identifiers) {
    final result = <Variable, Variable>{};
    for (final element in identifiers) {
      final variable = _newVar(block, 'var', _varOp(element));
      result[variable] = element;
    }

    return result;
  }

  UnaryOperation _unary(OperationKind kind, Operation op) {
    return UnaryOperation(kind, op);
  }

  VariableOperation _varOp(Variable variable) {
    return VariableOperation(variable);
  }
}
