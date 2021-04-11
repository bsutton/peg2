// @dart = 2.10
part of '../../parser_generator.dart';

class ExpressionsGenerator extends ExpressionVisitor<void> {
  final VariableAllocator allocator;

  List<Code> code;

  final Map<Expression, List<Code>> _failBlocks = {};

  final Map<Expression, List<Code>> _successBlocks = {};

  String _childVariable;

  ExpressionsGenerator({@required this.allocator, @required this.code});

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    final storage = <String, String>{};
    _storeVar(Members.ch, storage, code);
    _storeVar(Members.pos, storage, code);
    _storeVar(Members.failPos, storage, code);
    _storeVar(Members.failStart, storage, code);
    _storeVar(Members.failures, storage, code);
    _acceptNode(child, code);
    if (variable != null) {
      code << assignFinal(variable, literalNull);
    }

    _restoreVars(storage, code);
    _childVariable = variable;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final variable = _allocNodeVar(node);
    final matchAny = call$(Members.matchAny);
    if (variable == null) {
      code << matchAny.statement;
    } else {
      code << assignFinal(variable, matchAny);
    }

    _childVariable = variable;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    if (variable == null) {
      _acceptNode(child, code);
    } else {
      code << declareVariable(refer('String?'), variable);
      final varStart = allocator.alloc();
      code << assignFinal(varStart, refer(Members.pos));
      _acceptNode(child, code);
      code <<
          if$(refer(Members.ok), (code) {
            code <<
                assign(
                    variable,
                    callMethod(Members.source, 'substring',
                        [refer(varStart), refer(Members.pos)]));
          });
    }

    _childVariable = variable;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final variable = _allocNodeVar(node);
    final ranges = <int>[];
    for (final group in node.ranges.groups) {
      ranges.add(group.start);
      ranges.add(group.end);
    }

    if (ranges.length == 2) {
      if (ranges[0] == ranges[1]) {
        final char = ranges[0];
        final matchChar =
            call$(Members.matchChar, [literal(char), literal(char)]);
        if (variable == null) {
          code << matchChar.statement;
        } else {
          code << assignFinal(variable, matchChar);
        }
      } else {
        final start = ranges[0];
        final end = ranges[1];
        final matchRange =
            call$(Members.matchRange, [literal(start), literal(end)]);
        if (variable == null) {
          code << matchRange.statement;
        } else {
          code << assignFinal(variable, matchRange);
        }
      }
    } else {
      final varRange = allocator.alloc();
      code << assignConst(varRange, literalList(ranges));
      final matchRange = call$(Members.matchRanges, [refer(varRange)]);
      if (variable == null) {
        code << matchRange.statement;
      } else {
        code << assignFinal(variable, matchRange);
      }
    }

    _childVariable = variable;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final variable = _allocNodeVar(node);
    final text = node.text;
    if (text.isEmpty) {
      if (variable != null) {
        declareVariable(refer('String?'), variable);
        code << assign(variable, literalString(''));
      }

      code << assign(Members.ok, literalTrue);
    } else if (text.length == 1) {
      final char = text.codeUnitAt(0);
      final matchChar =
          call$(Members.matchChar, [literal(char), literalString(text)]);
      if (variable == null) {
        code << matchChar.statement;
      } else {
        code << assignFinal(variable, matchChar);
      }
    } else {
      final matchString = call$(Members.matchString, [literalString(text)]);
      if (variable == null) {
        code << matchString.statement;
      } else {
        code << assignFinal(variable, matchString);
      }
    }

    _childVariable = variable;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    final storage = <String, String>{};
    _storeVar(Members.ch, storage, code);
    _storeVar(Members.pos, storage, code);
    _storeVar(Members.failPos, storage, code);
    _storeVar(Members.failStart, storage, code);
    _storeVar(Members.failures, storage, code);
    _acceptNode(child, code);
    if (variable != null) {
      code << assignFinal(variable, literalNull);
    }

    _restoreVars(storage, code);
    code << assign(Members.ok, refer(Members.ok).negate());
    _childVariable = variable;
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    void fail(List<Code> code) {
      code << break$;
    }

    if (variable == null) {
      final varCount = allocator.alloc();
      code << assignVar(varCount, literal(0));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            _generateEpilogue(node, code, null, fail);
            code << refer(varCount).postOp('++').statement;
          });

      code << assign(Members.ok, refer(varCount).notEqualTo(literal(0)));
    } else {
      final listType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(listType), variable);
      final varList = allocator.alloc();
      code << assignFinal(varList, literalList([], refer(child.resultType)));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            _generateEpilogue(node, code, null, fail);
            final element =
                Utils.getNullCheckedValue(_childVariable, child.resultType);
            code << callMethod(varList, 'add', [refer(element)]).statement;
          });

      code <<
          if$(property(varList, 'isNotEmpty'), (code) {
            code << assign(variable, refer(varList));
            code << assign(Members.ok, literalTrue);
          });
    }

    _childVariable = variable;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    _acceptNode(child, code);
    if (variable != null) {
      code << assignFinal(variable, refer(_childVariable));
    }

    code << assign(Members.ok, literalTrue);
    _childVariable = variable;
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final variable = _allocNodeVar(node);
    final rule = node.rule;
    final level = node.level;
    final expressions = node.expressions;
    void failure(List<Code> code) {
      if (rule.kind == ProductionRuleKind.terminal &&
          level == 0 &&
          !node.isOptional) {
        final arguments = <_cb.Expression>[];
        arguments.add(literalString(rule.name));
        code << call$(Members.fail, arguments).statement;
      }
    }

    if (rule.kind == ProductionRuleKind.terminal &&
        level == 0 &&
        !node.isOptional) {
      code << assign(Members.failPos, refer(Members.pos));
    }

    if (variable != null) {
      final returnType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(returnType), variable);
    }

    if (expressions.length > 1) {
      switch (rule.kind) {
        case ProductionRuleKind.nonterminal:
          _generateMultipleChoiceNonterminal(node, variable, failure);
          break;
        default:
          _generateMultipleChoiceTerminal(node, variable, failure);
      }
    } else {
      _generateSingleChoice(node, variable, failure);
    }

    _childVariable = variable;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final variable = _allocNodeVar(node);
    final expressions = node.expressions;
    final localVariables = <String>[];
    final semanticVariables = <String>[];
    final types = <String>[];
    final code$ = code;
    if (variable != null) {
      final resultType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(resultType), variable);
    }

    if (expressions.length > 1) {
      var needTest = false;
      for (var i = 0; i < expressions.length; i++) {
        final child = expressions[i];
        if (needTest) {
          code <<
              if$(refer(Members.ok), (code) {
                this.code = code;
                _acceptNode(child, code);
              });
        } else {
          _acceptNode(child, code);
        }

        localVariables.add(_childVariable);
        semanticVariables.add(child.variable);
        types.add(child.resultType);
        needTest = !child.isOptional;
      }
    } else {
      final child = expressions[0];
      _acceptNode(child, code);
      localVariables.add(_childVariable);
      semanticVariables.add(child.variable);
      types.add(child.resultType);
    }

    if (variable != null || node.actionIndex != null) {
      final errors = <String>[];
      void action(List<Code> code) {
        final generator = ActionCodeGenerator(
          code: code,
          actionSource: node.actionSource,
          localVariables: localVariables,
          resultType: node.resultType,
          semanticVariables: semanticVariables,
          types: types,
          variable: variable,
        );
        generator.generate(errors);
        if (errors.isNotEmpty) {
          final message = 'Error generating result for expression: $node';
          throw StateError(message);
        }
      }

      if (expressions.last.isOptional) {
        action(code);
        _successBlocks[node] = code;
      } else {
        code <<
            if$(refer(Members.ok), (code) {
              action(code);
              _successBlocks[node] = code;
            });
      }
    }

    code = code$;
    _childVariable = variable;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final variable = _allocNodeVar(node);
    final child = node.expression;
    void fail(List<Code> code) {
      code <<
          if$(refer(Members.ok).negate(), (code) {
            code << break$;
          });
    }

    if (variable == null) {
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            fail(code);
          });

      code << assign(Members.ok, literalTrue);
    } else {
      final listType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(listType), variable);
      final varList = allocator.alloc();
      code << assignFinal(varList, literalList([], refer(child.resultType)));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            fail(code);
            final element =
                Utils.getNullCheckedValue(_childVariable, child.resultType);
            code << callMethod(varList, 'add', [refer(element)]).statement;
          });

      //
      code <<
          if$(refer(Members.ok).assign(literalTrue), (code) {
            code << assign(variable, refer(varList));
          });
    }

    _childVariable = variable;
  }

  void _acceptNode(Expression node, List<Code> code) {
    _runBlock(code, () => node.accept(this));
  }

  String _allocNodeVar(Expression node) {
    if (node.resultUsed) {
      return allocator.alloc();
    }

    return null;
  }

  bool _canSequenceChangePos(SequenceExpression node) {
    var count = 0;
    for (final child in node.expressions) {
      if (child is AndPredicateExpression) {
        continue;
      }

      if (child is NotPredicateExpression) {
        continue;
      }

      if (++count > 1) {
        return true;
      }
    }

    return false;
  }

  void _generateEpilogue(Expression node, List<Code> code,
      Function(List<Code>) success, Function(List<Code>) fail) {
    final successBlock = _successBlocks[node];
    final failBlock = _failBlocks[node];
    if (successBlock != null && success != null) {
      success(successBlock);
      success = null;
    }

    if (failBlock != null && fail != null) {
      fail(failBlock);
      fail = null;
    }

    if (success != null || fail != null) {
      final ifElse = _ifElse(refer(Members.ok));
      if (success != null) {
        ifElse.ifCode(success);
      }

      if (fail != null) {
        ifElse.elseCode(fail);
      }

      code << lazyCode(() => Block.of(ifElse.generate()));
    }
  }

  void _generateMultipleChoiceNonterminal(OrderedChoiceExpression node,
      String variable, void Function(List<Code>) failure) {
    final expressions = node.expressions;
    var needSavePos = false;
    for (final child in expressions) {
      if (_canSequenceChangePos(child)) {
        needSavePos = true;
        break;
      }
    }

    final storage = <String, String>{};
    _storeVar(Members.ch, storage, code);
    if (needSavePos) {
      _storeVar(Members.pos, storage, code);
    }

    code <<
        while$(literalTrue, (code) {
          for (var i = 0; i < expressions.length; i++) {
            final child = expressions[i];
            if (variable != null) {
              _childVariable = allocator.alloc();
            }

            _acceptNode(child, code);
            void success(List<Code> code) {
              if (variable != null) {
                code << assign(variable, refer(_childVariable));
              }

              code << break$;
            }

            _generateEpilogue(child, code, success, null);
            if (_canSequenceChangePos(child)) {
              _restoreVars(storage, code);
            } else {
              _restoreVar(Members.ch, storage, code);
            }
          }

          code << break$;
        });

    failure(code);

    if (node.level == 0) {
      code << refer(variable).returned.statement;
    }
  }

  void _generateMultipleChoiceTerminal(OrderedChoiceExpression node,
      String variable, void Function(List<Code>) failure) {
    final expressions = node.expressions;
    var needSavePos = false;
    for (final child in expressions) {
      if (_canSequenceChangePos(child)) {
        needSavePos = true;
        break;
      }
    }

    final storage = <String, String>{};
    _storeVar(Members.ch, storage, code);
    if (needSavePos) {
      _storeVar(Members.pos, storage, code);
    }

    code <<
        while$(literalTrue, (code) {
          for (var i = 0; i < expressions.length; i++) {
            final child = expressions[i];
            if (variable != null) {
              _childVariable = allocator.alloc();
            }

            _acceptNode(child, code);
            void success(List<Code> code) {
              if (variable != null) {
                code << assign(variable, refer(_childVariable));
              }

              code << break$;
            }

            _generateEpilogue(child, code, success, null);
            if (_canSequenceChangePos(child)) {
              _restoreVars(storage, code);
            } else {
              _restoreVar(Members.ch, storage, code);
            }
          }

          code << break$;
        });

    failure(code);

    if (node.level == 0) {
      code << refer(variable).returned.statement;
    }
  }

  void _generateSingleChoice(OrderedChoiceExpression node, String variable,
      void Function(List<Code>) failure) {
    final child = node.expressions[0];
    final needSavePos = _canSequenceChangePos(child);
    if (variable != null) {
      _childVariable = allocator.alloc();
    }

    final storage = <String, String>{};
    if (needSavePos) {
      _storeVar(Members.ch, storage, code);
      _storeVar(Members.pos, storage, code);
    }

    _acceptNode(child, code);
    void success(List<Code> code) {
      if (variable != null) {
        code << assign(variable, refer(_childVariable));
      }
    }

    void fail(List<Code> code) {
      _restoreVars(storage, code);
      failure(code);
      _failBlocks[node] = code;
    }

    _generateEpilogue(child, code, success, fail);
    if (node.level == 0) {
      if (variable == null) {
        code << literalNull.returned.statement;
      } else {
        code << refer(variable).returned.statement;
      }
    }
  }

  IfElseGenerator _ifElse(_cb.Expression expression) {
    return IfElseGenerator(expression);
  }

  void _restoreVar(String name, Map<String, String> storage, List<Code> code) {
    if (!storage.containsKey(name)) {
      throw StateError('The variable was not stored: $name');
    }

    final variable = storage[name];
    code << assign(name, refer(variable));
  }

  void _restoreVars(Map<String, String> storage, List<Code> code) {
    for (final key in storage.keys) {
      _restoreVar(key, storage, code);
    }
  }

  void _runBlock(List<Code> code, void Function() f) {
    final code$ = this.code;
    this.code = code;
    f();
    this.code = code$;
  }

  String _storeVar(String name, Map<String, String> storage, List<Code> code) {
    if (storage.containsKey(name)) {
      throw StateError('Variable already stored: $name');
    }

    final variable = allocator.alloc();
    code << assignFinal(variable, refer(name));
    storage[name] = variable;
    return variable;
  }

  void _visitSymbol(SymbolExpression node) {
    final variable = _allocNodeVar(node);
    final rule = node.expression.rule;
    final identifier = Helper.getRuleIdentifier(rule);
    final invoke = call$(identifier);
    if (variable == null) {
      code << invoke.statement;
    } else {
      code << assignFinal(variable, invoke);
    }

    _childVariable = variable;
  }
}
