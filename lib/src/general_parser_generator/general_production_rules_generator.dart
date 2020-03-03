part of '../../general_parser_generator.dart';

class GeneralProductionRulesGenerator extends ProductionRulesGenerator
    with ExpressionVisitor, OperationUtils {
  static const _paramCallerId = 'param_callerId';

  static const _paramProductive = 'param_productive';

  final _m = GeneralParserClassMembers();

  bool _isProductive;

  VariableAllocator _va;

  GeneralProductionRulesGenerator(
      Grammar grammar, ParserGeneratorOptions options)
      : super(grammar, options);

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    final rules = grammar.rules;
    for (final rule in rules) {
      var skip = false;
      if (rule.directCallers.length == 1) {
        switch (rule.kind) {
          case ProductionRuleKind.nonterminal:
            if (options.inlineNonterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.subterminal:
            if (options.inlineSubterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.terminal:
            if (options.inlineTerminals) {
              skip = true;
            }

            break;
          default:
        }
      }

      if (!skip) {
        final method = _generateRule(rule);
        methods.add(method);
      }
    }
  }

  VariableAllocator newVarAlloc() {
    var lastVariableId = 0;
    final result = VariableAllocator(() {
      final name = '\$${lastVariableId++}';
      return name;
    });

    return result;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(_paramProductive);
    context.saveVariable(b, _va, _m.c);
    context.saveVariable(b, _va, _m.pos);
    context.saveVariable(b, _va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    _visitChild(child, b, context, [_m.c, _m.pos]);
    context.restoreVariables(b);
    context.result = _va.newVar(b, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final context = contexts.last;
    final b = context.block;
    final result = _va.newVar(b, 'int', null);
    context.result = result;
    final test = ltOp(varOp(_m.c), varOp(_m.eof));
    void generate(BlockOperation b) {
      addAssign(b, varOp(result), varOp(_m.c));
      final testC = lteOp(varOp(_m.c), constOp(0xffff));
      final ternary = ternaryOp(testC, constOp(1), constOp(2));
      final assignPos = addAssignOp(varOp(_m.pos), ternary);
      final listAcc = listAccOp(varOp(_m.input), assignPos);
      addAssign(b, varOp(_m.c), listAcc);
    }

    _generateTestRangesByTest(b, test, generate);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final context = contexts.last;
    final b = context.block;
    final result = _va.newVar(b, 'String', null);
    context.result = result;
    final start = context.addVariable(b, _va, _m.pos);
    final productive = context.getArgument(_paramProductive);
    context.saveVariable(b, _va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    _visitChild(child, b, context);
    addIfVar(b, _m.success, (b) {
      final substring = Variable('substring');
      final callSubstring = mbrCallOp(
          varOp(_m.text), varOp(substring), [varOp(start), varOp(_m.pos)]);
      addAssign(b, varOp(result), callSubstring);
    });

    context.restoreVariables(b);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final context = contexts.last;
    final b = context.block;
    final ranges = <int>[];
    for (final range in node.ranges) {
      ranges.addAll(range);
    }

    Variable result;
    if (ranges.length <= 20) {
      var hasLongChars = false;
      for (var i = 0; i < ranges.length; i += 2) {
        if (ranges[i] > 0xffff || ranges[i + 1] > 0xffff) {
          hasLongChars = true;
        }
      }

      result = _va.newVar(b, 'int', null);

      void generate(BlockOperation b) {
        addAssign(b, varOp(result), varOp(_m.c));
        Operation assignPos;
        if (hasLongChars) {
          final testC = lteOp(varOp(_m.c), constOp(0xffff));
          final ternary = ternaryOp(testC, constOp(1), constOp(2));
          assignPos = addAssignOp(varOp(_m.pos), ternary);
        } else {
          assignPos = preIncOp(varOp(_m.pos));
        }

        final listAcc = listAccOp(varOp(_m.input), assignPos);
        addAssign(b, varOp(_m.c), listAcc);
      }

      _generateTestRangesByRanges(b, ranges, generate);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(constOp(ranges[i]));
        elements.add(constOp(ranges[i + 1]));
      }

      final list = listOp(null, elements);
      final chars = _va.newVar(b, 'const', list);
      final matchRanges = callOp(varOp(_m.matchRanges), [varOp(chars)]);
      result = _va.newVar(b, 'final', matchRanges);
    }

    context.result = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final context = contexts.last;
    final b = context.block;
    final text = node.text;
    final runes = text.runes;
    Variable result;
    if (runes.length == 1) {
      final rune = runes.first;
      result = _va.newVar(b, 'String', null);

      void generate(BlockOperation b) {
        addAssign(b, varOp(result), constOp(text));
        Operation posAssign;
        if (rune <= 0xffff) {
          posAssign = preIncOp(varOp(_m.pos));
        } else {
          posAssign = addAssignOp(varOp(_m.pos), constOp(2));
        }

        final listAcc = listAccOp(varOp(_m.input), posAssign);
        addAssign(b, varOp(_m.c), listAcc);
      }

      _generateTestRangesByRanges(b, [rune, rune], generate);
    } else if (runes.length > 1) {
      final rune = runes.first;
      result = _va.newVar(b, 'String', null);

      void generate(BlockOperation b) {
        final matchString = callOp(varOp(_m.matchString), [constOp(text)]);
        addAssign(b, varOp(result), matchString);
      }

      _generateTestRangesByRanges(b, [rune, rune], generate);
    } else {
      result = _va.newVar(b, 'final', constOp(''));
      addAssign(b, varOp(_m.success), constOp(true));
    }

    context.result = result;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final rule = node.expression.rule;
    final inline = options.inlineNonterminals && rule.directCallers.length == 1;
    _visitSymbol(node, inline);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(_paramProductive);
    context.saveVariable(b, _va, _m.c);
    context.saveVariable(b, _va, _m.pos);
    context.saveVariable(b, _va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    _visitChild(child, b, context, [_m.c, _m.pos]);
    addAssign(b, varOp(_m.success), notOp(varOp(_m.success)));
    context.restoreVariables(b);
    context.result = _va.newVar(b, 'var', null);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(_paramProductive);
    final returnType = node.returnType;
    final result = _va.newVar(b, returnType, null);
    context.result = result;
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    final passed = _va.newVar(b, 'var', constOp(false));
    addLoop(b, (b) {
      final child = node.expression;
      final next = _visitChild(child, b, context);
      addIfNotVar(b, _m.success, (b) {
        addAssign(b, varOp(_m.success), varOp(passed));
        addIfNotVar(b, _m.success, (b) {
          addAssign(b, varOp(result), constOp(null));
        });

        addBreak(b);
      });

      if (node.isProductive) {
        addIfElse(b, varOp(productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
        });
      } else {
        // Do nothing
      }

      addAssign(b, varOp(passed), constOp(true));
    });
  }

  @override
  void visitOptional(OptionalExpression node) {
    final context = contexts.last;
    final b = context.block;
    final child = node.expression;
    final next = _visitChild(child, b, context);
    context.result = next.result;
    var cannotOptimize = true;
    if (!node.isLast || child.isOptional) {
      cannotOptimize = false;
    }

    if (cannotOptimize) {
      addAssign(b, varOp(_m.success), constOp(true));
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final context = contexts.last;
    final b = context.block;
    final expressions = node.expressions;
    final returnType = node.returnType;
    final rule = node.rule;
    final isTopTerminal =
        node.parent == null && rule.kind == ProductionRuleKind.terminal;
    final isTerminal = rule.kind == ProductionRuleKind.terminal;
    final isNonterminal = rule.kind == ProductionRuleKind.nonterminal;
    final result = _va.newVar(b, returnType, null);
    context.result = result;
    final c = context.addVariable(b, _va, _m.c);
    final start = context.addVariable(b, _va, _m.pos);
    Variable failure;
    if (isTerminal) {
      failure = _va.newVar(b, 'var', varOp(_m.pos));
    }

    //final ifNotSuccess = BlockOperation();
    if (expressions.length > 1) {
      addLoop(b, (b) {
        for (var i = 0; i < expressions.length; i++) {
          final child = expressions[i];
          final next = _visitChild(child, b, context, [_m.c, _m.pos]);
          if (isTerminal) {
            final test = ltOp(varOp(failure), varOp(_m.failure));
            addIf(b, test, (b) {
              addAssign(b, varOp(failure), varOp(_m.failure));
            });
          }

          addIfVar(b, _m.success, (b) {
            addAssign(b, varOp(result), varOp(next.result));
            addBreak(b);
          });

          if (child.expressions.length > 1) {
            addAssign(b, varOp(_m.c), varOp(c));
            addAssign(b, varOp(_m.pos), varOp(start));
          }

          if (i < expressions.length - 1) {
            //
          } else {
            if (isTerminal) {
              addAssign(b, varOp(_m.failure), varOp(failure));
            }

            addBreak(b);
          }
        }
      });
    } else {
      final child = expressions[0];
      final next = _visitChild(child, b, context, [_m.c, _m.pos]);
      addAssign(b, varOp(result), varOp(next.result));
    }

    final startTerminals = node.startTerminals;
    void fail(BlockOperation b) {
      final terminals = startTerminals.map((e) => e.name);
      final elements = terminals.map(constOp).toList();
      final list = listOp('const', elements);
      addCall(b, varOp(_m.fail), [list]);
    }

    if (isTopTerminal) {
      final testSuccess = notOp(varOp(_m.success));
      final testError = lteOp(varOp(_m.error), varOp(_m.failure));
      final test = landOp(testSuccess, testError);
      addIf(b, test, fail);
    } else if (isNonterminal) {
      final testSuccess = notOp(varOp(_m.success));
      final testError = eqOp(varOp(_m.error), varOp(start));
      final test = landOp(testSuccess, testError);
      addIf(b, test, fail);
    }

    /*
    if (isTopTerminal) {
      final test1 = ltOp(varOp(_m.error), varOp(_m.failure));
      addIf(ifNotSuccess, test1, (b) {
        // code: _error = _failure;
        // code: _expected = [];
        addAssign(b, varOp(_m.error), varOp(_m.failure));
        addAssign(b, varOp(_m.expected), listOp(null, []));
      });

      final test2 = eqOp(varOp(_m.error), varOp(_m.failure));
      addIf(ifNotSuccess, test2, (b) {
        final add = Variable('add');
        final name = rule.name;
        // code: _expected.add(name);
        addMbrCall(b, varOp(_m.expected), varOp(add), [constOp(name)]);
      });
    } else if (isNonterminal) {
      final test = eqOp(varOp(start), varOp(_m.error));
      addIf(ifNotSuccess, test, (b) {
        final terminals = startTerminals.map((e) => e.name);
        if (terminals.length == 1) {
          final terminal = terminals.first;
          final name = constOp(terminal);
          final add = Variable('add');
          addMbrCall(b, varOp(_m.expected), varOp(add), [name]);
        } else {
          final elements = terminals.map(constOp).toList();
          final list = listOp('const', elements);
          final addAll = Variable('addAll');
          addMbrCall(b, varOp(_m.expected), varOp(addAll), [list]);
        }
      });
    }

    if (ifNotSuccess.operations.isNotEmpty) {
      final test = notOp(varOp(_m.success));
      final end = condOp(test, ifNotSuccess);
      addOp(b, end);
    }
    */
  }

  @override
  void visitSequence(SequenceExpression node) {
    if (node.rule.name == "'semantic value'") {
      var x = 0;
    }

    final context = contexts.last;
    final b = context.block;
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    final returnType = node.returnType;
    final result = _va.newVar(b, returnType, null);
    context.result = result;
    void Function(BlockOperation) onSuccess;
    final results = <Expression, Variable>{};
    final isLastChildOptional = expressions.last.isOptional;
    void plunge(BlockOperation b, int index) {
      if (index > expressions.length - 1) {
        return;
      }

      final child = expressions[index];
      _isProductive = child.isProductive;
      ProductionRulesGeneratorContext next;
      if (index == 0) {
        next = _visitChild(child, b, context, [_m.c, _m.pos]);
      } else {
        next = _visitChild(child, b, context);
      }

      final childResult = next.result;
      results[child] = childResult;
      if (child.variable != null) {
        variables[child] = childResult;
      }

      if (index < expressions.length - 1) {
        if (child.isOptional) {
          plunge(b, index + 1);
        } else {
          addIfVar(b, _m.success, (b) {
            plunge(b, index + 1);
          });
        }
      } else {
        if (hasAction) {
          addIfVar(b, _m.success, (b) {
            _buildAction(b, node, result, variables);
          });
        } else {
          if (variables.isEmpty) {
            onSuccess = (b) {
              final variable = results.values.first;
              addAssign(b, varOp(result), varOp(variable));
            };
          } else if (variables.length == 1) {
            onSuccess = (b) {
              final expression = variables.keys.first;
              final variable = results[expression];
              addAssign(b, varOp(result), varOp(variable));
            };
          } else {
            if (node.isProductive) {
              onSuccess = (b) {
                addIfVar(b, _m.success, (b) {
                  final list =
                      listOp(null, variables.values.map(varOp).toList());
                  addAssign(b, varOp(result), list);
                });
              };
            } else {
              //addAssign(b, varOp(result), null);
            }
          }
        }

        if (onSuccess != null) {
          if (isLastChildOptional) {
            onSuccess(b);
          } else {
            addIfVar(b, _m.success, onSuccess);
          }
        }
      }

      if (index == 1) {
        addIfNotVar(b, _m.success, (b) {
          final c = context.getVariable(_m.c);
          final pos = context.getVariable(_m.pos);
          addAssign(b, varOp(_m.c), varOp(c));
          addAssign(b, varOp(_m.pos), varOp(pos));
        });
      }
    }

    plunge(b, 0);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final rule = node.expression.rule;
    final inline = options.inlineSubterminals && rule.directCallers.length == 1;
    _visitSymbol(node, inline);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final rule = node.expression.rule;
    final inline = options.inlineNonterminals && rule.directCallers.length == 1;
    _visitSymbol(node, inline);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(_paramProductive);
    final returnType = node.returnType;
    final result = _va.newVar(b, returnType, null);
    context.result = result;
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    addLoop(b, (b) {
      final child = node.expression;
      final next = _visitChild(child, b, context);
      addIfNotVar(b, _m.success, (b) {
        addAssign(b, varOp(_m.success), constOp(true));
        addBreak(b);
      });
      if (node.isProductive) {
        addIfElse(b, varOp(productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
        });
      } else {
        // Do nothing
      }
    });
  }

  void _buildAction(BlockOperation b, SequenceExpression node, Variable result,
      Map<Expression, Variable> variables) {
    for (final expression in variables.keys) {
      final variable = Variable(expression.variable, true);
      final parameter =
          paramOp('final', variable, varOp(variables[expression]));
      b.operations.add(parameter);
    }

    final $$ = Variable('\$\$', true);
    final returnType = node.returnType;
    final parameter = paramOp(returnType, $$, null);
    b.operations.add(parameter);
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

    final action = ActionOperation(variables.values.map(varOp).toList(), code);
    b.operations.add(action);
    addAssign(b, varOp(result), varOp($$));
  }

  MethodOperation _generateRule(ProductionRule rule) {
    _va = newVarAlloc();
    final body = BlockOperation();
    final context = ProductionRulesGeneratorContext(body);
    final expression = rule.expression;
    final callerId = context.addArgument(_paramCallerId, _va.alloc(true));
    final productive = context.addArgument(_paramProductive, _va.alloc(true));
    final id = expression.id;
    final name = _getRuleMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', callerId));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;
    Variable start;

    void generate() {
      final b = context.block;
      if (_needMemoize(rule)) {
        final callerId = context.getArgument(_paramCallerId);
        final memoized =
            callOp(varOp(_m.memoized), [constOp(id), varOp(callerId)]);
        addIf(b, memoized, (b) {
          final convert = convertOp(varOp(_m.mresult), returnType);
          addReturn(b, convert);
        });
      }

      final result = _va.newVar(b, returnType, null);
      context.result = result;
      final next = _visitChild(expression, b, context);
      addAssign(b, varOp(result), varOp(next.result));
      if (options.memoize && rule.directCallers.length > 1) {
        final listAccess =
            ListAccessOperation(varOp(_m.memoizable), varOp(callerId));
        final test =
            BinaryOperation(listAccess, OperationKind.equal, constOp(true));
        addIf(b, test, (b) {
          final memoize = callOp(
              varOp(_m.memoize), [constOp(id), varOp(start), varOp(result)]);
          addOp(b, memoize);
        });
      }

      addReturn(b, varOp(result));
    }

    generate();
    //final result = addMethod(returnType, name, params, (b) {});
    final result = MethodOperation(returnType, name, params, body);

    return result;
  }

  void _generateTestRangesByRanges(BlockOperation b, List<int> ranges,
      void Function(BlockOperation b) ifTrue) {
    final test = _testRanges(ranges);
    _generateTestRangesByTest(b, test, ifTrue);
  }

  void _generateTestRangesByTest(BlockOperation b, Operation test,
      void Function(BlockOperation b) ifTrue) {
    final testSuccess = binOp(OperationKind.assign, varOp(_m.success), test);
    addIfElse(b, testSuccess, (b) {
      ifTrue(b);
    }, (b) {
      addAssign(b, varOp(_m.failure), varOp(_m.pos));
    });
  }

  String _getRuleMethodName(ProductionRule rule) {
    var name = rule.name;
    switch (rule.kind) {
      case ProductionRuleKind.nonterminal:
        break;
      case ProductionRuleKind.terminal:
        name = _getTerminalName(name, rule.id);
        break;
      case ProductionRuleKind.subterminal:
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

  bool _needMemoize(ProductionRule rule) {
    if (!options.memoize) {
      return false;
    }

    final directCallers = rule.directCallers;
    if (directCallers.length == 1) {
      return false;
    }

    final parents = directCallers.map((e) => e.parent).toSet();
    if (parents.length == 1) {
      return false;
    }

    return true;
  }

  Operation _testRanges(List<int> ranges) {
    Operation op(int start, int end) {
      if (start == end) {
        return eqOp(varOp(_m.c), constOp(start));
      } else {
        final left = gteOp(varOp(_m.c), constOp(start));
        final right = lteOp(varOp(_m.c), constOp(end));
        return landOp(left, right);
      }
    }

    if (ranges[0] == 0 && ranges[1] == 0x10ffff) {
      // Allows match EOF
      ranges[1] = 0x10ffff + 1;
    }

    var result = op(ranges[0], ranges[1]);
    for (var i = 2; i < ranges.length; i += 2) {
      final right = op(ranges[i], ranges[i + 1]);
      result = lorOp(result, right);
    }

    return result;
  }

  ProductionRulesGeneratorContext _visitChild(Expression expression,
      BlockOperation block, ProductionRulesGeneratorContext context,
      [Iterable<Variable> variables]) {
    final next = context.copy(block, variables);
    contexts.add(next);
    expression.accept(this);
    contexts.removeLast();
    if (next.result == null) {
      throw StateError('Variable is not defined');
    }

    return next;
  }

  void _visitSymbol(SymbolExpression node, bool inline) {
    final context = contexts.last;
    final b = context.block;
    final rule = node.expression.rule;
    final name = Variable(_getRuleMethodName(rule));
    final cid = node.id;
    final startCharacters = node.startCharacters;
    final charGroups = startCharacters.groups;
    var predict = false;
    if (options.predict) {
      if (rule.kind == ProductionRuleKind.subterminal ||
          rule.kind == ProductionRuleKind.terminal) {
        if (charGroups.length < 10) {
          predict = true;
        }
      }
    }

    Variable generate(BlockOperation b) {
      Variable result;
      if (inline) {
        final child = rule.expression;
        final next = _visitChild(child, b, context);
        result = next.result;
      } else {
        Operation _productive;
        if (node.isProductive) {
          final productive = context.getArgument(_paramProductive);
          _productive = _isProductive ? varOp(productive) : constOp(false);
        } else {
          _productive = constOp(false);
        }

        final methodCall = callOp(varOp(name), [constOp(cid), _productive]);
        result = _va.newVar(b, 'final', methodCall);
      }

      return result;
    }

    if (predict) {
      final ranges = <int>[];
      for (final group in charGroups) {
        ranges.add(group.start);
        ranges.add(group.end);
      }

      final test = _testRanges(ranges);
      final returnType = node.returnType;
      final result = _va.newVar(b, returnType, null);
      addIfElse(b, test, (b) {
        final result = generate(b);
        addAssign(b, varOp(result), varOp(result));
      }, (b) {
        if (rule.expression.isSuccessful) {
          addAssign(b, varOp(_m.success), constOp(true));
        } else {
          addAssign(b, varOp(_m.success), constOp(false));
          //if (rule.kind == ProductionRuleKind.terminal) {
          //  final test = notOp(varOp(m.silence));
          //  addIf(b, test, (b) {
          //    addAssign(b, varOp(m.error), varOp(m.pos));
          //    final params = [varOp(m.pos), constOp(rule.name)];
          //    final fail = callOp(varOp(m.fail), params);
          //    addOp(b, fail);
          //  });
          //}
        }
      });

      context.result = result;
    } else {
      context.result = generate(b);
    }
  }
}
