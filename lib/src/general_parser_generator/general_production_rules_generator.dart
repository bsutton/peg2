part of '../../general_parser_generator.dart';

class GeneralProductionRulesGenerator extends ProductionRulesGenerator
    with ExpressionVisitor, OperationUtils {
  static const _paramCallerId = 'param_callerId';

  static const _paramProductive = 'param_productive';

  Variable localFailure;

  final m = GeneralParserClassMembers();

  bool notProductive;

  VariableAllocator va;

  final Map<Expression, Map<Variable, Variable>> _contexts = {};

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

  void runInBlock(BlockOperation b, void Function() f) {
    final pb = this.b;
    this.b = b;
    f();
    this.b = pb;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final productive = ctx.getArgument(_paramProductive);
    ctx.saveVariable(b, va, m.c, false);
    ctx.saveVariable(b, va, m.pos, false);
    ctx.saveVariable(b, va, productive, false);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    _visitChild(ctx, child);
    ctx.restoreVariables(b);
    ctx.result = va.newVar(b, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final result = va.newVar(b, 'int', null);
    ctx.result = result;
    final test = ltOp(varOp(m.c), varOp(m.eof));
    void generate(BlockOperation b) {
      addAssign(b, varOp(result), varOp(m.c));
      final testC = lteOp(varOp(m.c), constOp(0xffff));
      final ternary = ternaryOp(testC, constOp(1), constOp(2));
      final assignPos = addAssignOp(varOp(m.pos), ternary);
      final listAcc = listAccOp(varOp(m.input), assignPos);
      addAssign(b, varOp(m.c), listAcc);
    }

    _generateTestRangesByTest(b, test, generate);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final result = va.newVar(b, 'String', null);
    ctx.result = result;    
    final productive = ctx.getArgument(_paramProductive);
    ctx.saveVariable(b, va, productive);
    var start = context[m.pos];
    if (start == null) {
      start = va.newVar(b, 'final', varOp(m.pos));
      addToContext(node, m.pos, start);
    }

    addAssign(b, varOp(productive), constOp(false));
    node.expression.accept(this);
    addIfVar(b, m.success, (b) {
      final substring = Variable('substring');
      final callSubstring = mbrCallOp(
          varOp(m.text), varOp(substring), [varOp(start), varOp(m.pos)]);
      addAssign(b, varOp(result), callSubstring);
    });

    restoreVars(b, savedVars);
    resultVar = result;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
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

      result = va.newVar(b, 'int', null);

      void generate(BlockOperation b) {
        addAssign(b, varOp(result), varOp(m.c));
        Operation assignPos;
        if (hasLongChars) {
          final testC = lteOp(varOp(m.c), constOp(0xffff));
          final ternary = ternaryOp(testC, constOp(1), constOp(2));
          assignPos = addAssignOp(varOp(m.pos), ternary);
        } else {
          assignPos = preIncOp(varOp(m.pos));
        }

        final listAcc = listAccOp(varOp(m.input), assignPos);
        addAssign(b, varOp(m.c), listAcc);
      }

      _generateTestRangesByRanges(b, ranges, generate);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(constOp(ranges[i]));
        elements.add(constOp(ranges[i + 1]));
      }

      final list = listOp(null, elements);
      final chars = va.newVar(b, 'const', list);
      final matchRanges = callOp(varOp(m.matchRanges), [varOp(chars)]);
      result = va.newVar(b, 'final', matchRanges);
    }

    resultVar = result;
  }

  void visitInBlock(BlockOperation b, VariableAllocator va, Expression e) {
    runInBlock(b, () => e.accept(this));
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    final runes = text.runes;
    Variable result;
    if (runes.length == 1) {
      final rune = runes.first;
      result = va.newVar(b, 'String', null);

      void generate(BlockOperation b) {
        addAssign(b, varOp(result), constOp(text));
        Operation posAssign;
        if (rune <= 0xffff) {
          posAssign = preIncOp(varOp(m.pos));
        } else {
          posAssign = addAssignOp(varOp(m.pos), constOp(2));
        }

        final listAcc = listAccOp(varOp(m.input), posAssign);
        addAssign(b, varOp(m.c), listAcc);
      }

      _generateTestRangesByRanges(b, [rune, rune], generate);
    } else if (runes.length > 1) {
      final rune = runes.first;
      result = va.newVar(b, 'String', null);

      void generate(BlockOperation b) {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        addAssign(b, varOp(result), matchString);
      }

      _generateTestRangesByRanges(b, [rune, rune], generate);
    } else {
      result = va.newVar(b, 'final', constOp(''));
      addAssign(b, varOp(m.success), constOp(true));
    }

    resultVar = result;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final rule = node.expression.rule;
    final inline = options.inlineNonterminals && rule.directCallers.length == 1;
    _visitSymbol(node, inline);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final productive = ctx.getArgument(_paramProductive);
    ctx.saveVariable(b, va, m.c, false);
    ctx.saveVariable(b, va, m.pos, false);
    ctx.saveVariable(b, va, productive, false);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    _visitChild(ctx, child);
    addAssign(b, varOp(m.success), notOp(varOp(m.success)));
    ctx.result = va.newVar(b, 'final', null);
    ctx.restoreVariables(b);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final child = node.expression;
    final productive = ctx.getArgument(_paramProductive);
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    ctx.result = result;
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    final next = ctx.copy(b);
    contexts.add(next);
    next.variables.clear();
    final passed = va.newVar(b, 'var', constOp(false));
    addLoop(b, (b) {
      visitInBlock(b, va, child);
      addIfNotVar(b, m.success, (b) {
        addAssign(b, varOp(m.success), varOp(passed));
        addIfNotVar(b, m.success, (b) {
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

    contexts.removeLast();
  }

  @override
  void visitOptional(OptionalExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final next = ctx.copy(b);
    contexts.add(next);
    final child = node.expression;
    child.accept(this);
    ctx.result = next.result;
    addAssign(b, varOp(m.success), constOp(true));
    contexts.removeLast();
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final expressions = node.expressions;
    final returnType = node.returnType;
    final rule = node.rule;
    final isTopTerminal =
        node.parent == null && rule.kind == ProductionRuleKind.terminal;
    final isTerminal = rule.kind == ProductionRuleKind.terminal;
    final isNonterminal = rule.kind == ProductionRuleKind.nonterminal;
    final result = va.newVar(b, returnType, null);
    ctx.result = result;
    ctx.saveVariable(b, va, m.c, false);
    final start = ctx.saveVariable(b, va, m.pos, false);
    Variable failure;
    if (isTerminal) {
      failure = va.newVar(b, 'var', varOp(m.pos));
    }

    final ifNotSuccess = BlockOperation();
    if (expressions.length > 1) {
      addLoop(b, (b) {
        final next = ctx.copy(b);
        contexts.add(next);
        for (var i = 0; i < expressions.length; i++) {
          final child = expressions[i];
          runInBlock(b, () => child.accept(this));
          if (isTerminal) {
            final test = ltOp(varOp(failure), varOp(m.failure));
            addIf(b, test, (b) {
              addAssign(b, varOp(failure), varOp(m.failure));
            });
          }

          if (i < expressions.length - 1) {
            addIfVar(b, m.success, (b) {
              addAssign(b, varOp(result), varOp(next.result));
              addBreak(b);
            });
          } else {
            addIfVar(b, m.success, (b) {
              addAssign(b, varOp(result), varOp(next.result));
            });

            if (isTerminal) {
              addAssign(b, varOp(m.failure), varOp(failure));
            }

            addBreak(b);
          }
        }

        contexts.removeLast();
      });
    } else {
      final next = ctx.copy(b);
      contexts.add(next);
      final child = expressions[0];
      child.accept(this);
      addAssign(b, varOp(result), varOp(next.result));
      ctx.restoreVariables(ifNotSuccess);
      contexts.removeLast();
    }

    final startTerminals = node.startTerminals;
    if (isTopTerminal) {
      final test1 = ltOp(varOp(m.error), varOp(m.failure));
      addIf(ifNotSuccess, test1, (b) {
        addAssign(b, varOp(m.error), varOp(m.failure));
        addAssign(b, varOp(m.expected), listOp(null, []));
      });

      final test2 = eqOp(varOp(m.error), varOp(m.failure));
      addIf(ifNotSuccess, test2, (b) {
        final add = Variable('add');
        final name = rule.name;
        addMbrCall(b, varOp(m.expected), varOp(add), [constOp(name)]);
      });
    } else if (isNonterminal) {
      final test = eqOp(varOp(start), varOp(m.error));
      addIf(ifNotSuccess, test, (b) {
        final terminals = startTerminals.map((e) => e.name);
        if (terminals.length == 1) {
          final terminal = terminals.first;
          final name = constOp(terminal);
          final add = Variable('add');
          addMbrCall(b, varOp(m.expected), varOp(add), [name]);
        } else {
          final elements = terminals.map(constOp).toList();
          final list = listOp('const', elements);
          final addAll = Variable('addAll');
          addMbrCall(b, varOp(m.expected), varOp(addAll), [list]);
        }
      });
    }

    if (ifNotSuccess.operations.isNotEmpty) {
      final test = notOp(varOp(m.success));
      final end = condOp(test, ifNotSuccess);
      addOp(b, end);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final ctx = contexts.last;
    final b = ctx.block;
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    ctx.result = result;
    localFailure = va.newVar(b, 'int', null);
    void Function(BlockOperation) onSuccess;
    Operation atEnd;
    final results = <Expression, Variable>{};
    void plunge(BlockOperation b, int index) {
      if (index > expressions.length - 1) {
        return;
      }

      final next = ctx.copy(b);
      contexts.add(next);
      if (index > 0) {
        next.variables.clear();
      }

      final child = expressions[index];
      notProductive = !child.isProductive;
      visitInBlock(b, va, child);
      final childResult = next.result;
      results[child] = childResult;
      if (child.variable != null) {
        variables[child] = childResult;
      }

      if (index < expressions.length - 1) {
        if (child.isOptional) {
          plunge(b, index + 1);
        } else {
          addIfVar(b, m.success, (b) {
            runInBlock(b, () => plunge(b, index + 1));
          });
        }
      } else {
        if (hasAction) {
          addIfVar(b, m.success, (b) {
            _buildAction(b, node, result, variables);
          });
        } else {
          if (variables.isEmpty) {
            final variable = results.values.first;
            addAssign(b, varOp(result), varOp(variable));
          } else if (variables.length == 1) {
            final expression = variables.keys.first;
            final variable = results[expression];
            addAssign(b, varOp(result), varOp(variable));
          } else {
            if (node.isProductive) {
              addIfVar(b, m.success, (b) {
                final list = listOp(null, variables.values.map(varOp).toList());
                addAssign(b, varOp(result), list);
              });
            } else {
              //addAssign(b, varOp(result), null);
            }
          }
        }

        if (onSuccess != null) {
          addIfVar(b, m.success, onSuccess);
        }

        if (atEnd != null) {
          //
        }

        contexts.removeLast();
      }
    }

    runInBlock(b, () => plunge(b, 0));
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
    final ctx = contexts.last;
    final b = ctx.block;
    final productive = ctx.getArgument(_paramProductive);
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    final next = ctx.copy(b);
    contexts.add(next);
    next.variables.clear();
    addLoop(b, (b) {
      final child = node.expression;
      visitInBlock(b, va, child);
      addIfNotVar(b, m.success, addBreak);
      if (node.isProductive) {
        addIfElse(b, varOp(productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
        });
      } else {
        // Do nothing
      }
    });

    addAssign(b, varOp(m.success), constOp(true));
    contexts.removeLast();
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
    va = newVarAlloc();
    final body = BlockOperation();
    final ctx = ProductionRulesGeneratorContext(body);
    final expression = rule.expression;
    final callerId = ctx.addArgument(_paramCallerId, va.alloc(true));
    final productive = ctx.addArgument(_paramProductive, va.alloc(true));
    final id = expression.id;
    final name = _getRuleMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', callerId));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;
    Variable start;

    void generate(BlockOperation b) {
      if (options.memoize && rule.directCallers.length > 1) {
        final memoized =
            callOp(varOp(m.memoized), [constOp(id), varOp(callerId)]);
        addIf(b, memoized, (b) {
          final convert = convertOp(varOp(m.mresult), returnType);
          addReturn(b, convert);
        });

        start = va.newVar(b, 'final', varOp(m.pos));
        addToContext(expression, m.pos, start);
      }

      final result = va.newVar(b, returnType, null);
      runInBlock(b, () => expression.accept(this));
      addAssign(b, varOp(result), varOp(resultVar));
      if (options.memoize && rule.directCallers.length > 1) {
        final listAccess =
            ListAccessOperation(varOp(m.memoizable), varOp(callerId));
        final test =
            BinaryOperation(listAccess, OperationKind.equal, constOp(true));
        addIf(b, test, (b) {
          final memoize = callOp(
              varOp(m.memoize), [constOp(id), varOp(start), varOp(result)]);
          addOp(b, memoize);
        });
      }

      addReturn(b, varOp(result));
    }

    contexts.add(ctx);
    generate(ctx.block);
    contexts.removeLast();

    final result = addMethod(returnType, name, params, (b) {});
    return result;
  }

  void _generateTestRangesByRanges(BlockOperation b, List<int> ranges,
      void Function(BlockOperation b) ifTrue) {
    final test = _testRanges(ranges);
    _generateTestRangesByTest(b, test, ifTrue);
  }

  void _generateTestRangesByTest(BlockOperation b, Operation test,
      void Function(BlockOperation b) ifTrue) {
    final testSuccess = binOp(OperationKind.assign, varOp(m.success), test);
    addIfElse(b, testSuccess, (b) {
      runInBlock(b, () => ifTrue(b));
    }, (b) {
      addAssign(b, varOp(m.failure), varOp(m.pos));
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

  Operation _testRanges(List<int> ranges) {
    Operation op(int start, int end) {
      if (start == end) {
        return eqOp(varOp(m.c), constOp(start));
      } else {
        final left = gteOp(varOp(m.c), constOp(start));
        final right = lteOp(varOp(m.c), constOp(end));
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

  ProductionRulesGeneratorContext _visitChild(
      ProductionRulesGeneratorContext context, Expression expression,
      [void Function(ProductionRulesGeneratorContext) init]) {
    final next = context.copy(context.block);
    contexts.add(next);
    if (init != null) {
      init(next);
    }

    expression.accept(this);
    contexts.removeLast();
    return next;
  }

  void _visitSymbol(SymbolExpression node, bool inline) {
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

    void generate() {
      if (inline) {
        final child = rule.expression;
        visitInBlock(b, va, child);
      } else {
        Operation isProductive;
        if (node.isProductive) {
          isProductive = notProductive ? constOp(false) : varOp(productive);
        } else {
          isProductive = constOp(false);
        }

        final methodCall = callOp(varOp(name), [constOp(cid), isProductive]);
        final result = va.newVar(b, 'final', methodCall);
        resultVar = result;
      }
    }

    if (predict) {
      final ranges = <int>[];
      for (final group in charGroups) {
        ranges.add(group.start);
        ranges.add(group.end);
      }

      final test = _testRanges(ranges);
      final returnType = node.returnType;
      final result = va.newVar(b, returnType, null);
      addIfElse(b, test, (b) {
        runInBlock(b, generate);
        addAssign(b, varOp(result), varOp(resultVar));
      }, (b) {
        if (rule.expression.isSuccessful) {
          addAssign(b, varOp(m.success), constOp(true));
        } else {
          addAssign(b, varOp(m.success), constOp(false));
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

      resultVar = result;
    } else {
      runInBlock(b, generate);
    }
  }
}
