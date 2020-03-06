part of '../../common_generators.dart';

abstract class ExpressionsToOperationsGenerator<M extends ParserClassMembers>
    extends ExpressionVisitor with OperationUtils {
  ProductionRulesGeneratorContext context;

  bool isProductive;

  final M m;

  final String parameterCallerId = 'parameterCallerId';

  final String parameterProductive = 'parameterProductive';

  VariableAllocator va;

  ExpressionsToOperationsGenerator(this.m);

  void buildAction(BlockOperation b, SequenceExpression node, Variable result,
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

  Operation createTestOperationForRanges(
      Variable c, SparseBoolList ranges, bool canMacthEof) {
    final list = SparseBoolList();
    for (final group in ranges.groups) {
      final g = GroupedRangeList<bool>(group.start, group.end, true);
      list.addGroup(g);
    }

    Operation op(int start, int end) {
      if (start == end) {
        return eqOp(varOp(c), constOp(start));
      } else {
        final left = gteOp(varOp(c), constOp(start));
        final right = lteOp(varOp(c), constOp(end));
        return landOp(left, right);
      }
    }

    if (canMacthEof) {
      final group = GroupedRangeList<bool>(0x10ffff + 1, 0x10ffff + 1, true);
      list.addGroup(group);
    }

    final groups = list.groups.toList();
    final first = groups.first;
    var result = op(first.start, first.end);
    for (var i = 1; i < groups.length; i++) {
      final group = groups[i];
      final right = op(group.start, group.end);
      result = lorOp(result, right);
    }

    return result;
  }

  void generateSequence(
      SequenceExpression node,
      ProductionRulesGeneratorContext Function(
              Expression, BlockOperation, ProductionRulesGeneratorContext, bool)
          visit,
      bool Function(Expression) isOptional) {
    final b = context.block;
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    context.result = result;
    void Function(BlockOperation) onSuccess;
    final results = <Expression, Variable>{};
    final isLastChildOptional = expressions.last.isOptional;
    void plunge(BlockOperation b, int index) {
      if (index > expressions.length - 1) {
        return;
      }

      final child = expressions[index];
      isProductive = child.isProductive;
      ProductionRulesGeneratorContext next;
      if (index == 0) {
        next = visit(child, b, context, true);
      } else {
        next = visit(child, b, context, false);
      }

      final childResult = next.result;
      results[child] = childResult;
      if (child.variable != null) {
        variables[child] = childResult;
      }

      if (index < expressions.length - 1) {
        if (isOptional(child)) {
          plunge(b, index + 1);
        } else {
          addIfVar(b, m.success, (b) {
            plunge(b, index + 1);
          });
        }
      } else {
        if (hasAction) {
          addIfVar(b, m.success, (b) {
            buildAction(b, node, result, variables);
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
                addIfVar(b, m.success, (b) {
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
            addIfVar(b, m.success, onSuccess);
          }
        }
      }

      if (index == 1) {
        addIfNotVar(b, m.success, (b) {
          final c = context.getAlias(m.c);
          final pos = context.getAlias(m.pos);
          addAssign(b, varOp(m.c), varOp(c));
          addAssign(b, varOp(m.pos), varOp(pos));
        });
      }
    }

    plunge(b, 0);
  }

  VariableAllocator newVarAlloc() {
    var lastVariableId = 0;
    final result = VariableAllocator(() {
      final name = '\$${lastVariableId++}';
      return name;
    });

    return result;
  }

  void testRanges(BlockOperation b, Variable c, SparseBoolList ranges,
      bool canMacthEof, void Function(BlockOperation b) ifTrue) {
    final test = createTestOperationForRanges(c, ranges, canMacthEof);
    testRangesWithOperation(b, test, ifTrue);
  }

  void testRangesWithOperation(BlockOperation b, Operation test,
      void Function(BlockOperation b) ifTrue) {
    final testSuccess = binOp(OperationKind.assign, varOp(m.success), test);
    addIfElse(b, testSuccess, (b) {
      ifTrue(b);
    }, (b) {
      addAssign(b, varOp(m.failure), varOp(m.pos));
    });
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, m.c);
    context.saveVariable(b, va, m.pos);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context);
    context.restoreVariables(b);
    context.result = va.newVar(b, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final b = context.block;
    final result = va.newVar(b, 'int', null);
    context.result = result;
    final c = context.getAlias(m.c);
    final test = ltOp(varOp(c), varOp(m.eof));
    void generate(BlockOperation b) {
      addAssign(b, varOp(result), varOp(m.c));
      final testC = lteOp(varOp(c), constOp(0xffff));
      final ternary = ternaryOp(testC, constOp(1), constOp(2));
      final assignPos = addAssignOp(varOp(m.pos), ternary);
      final listAcc = listAccOp(varOp(m.input), assignPos);
      addAssign(b, varOp(m.c), listAcc);
    }

    testRangesWithOperation(b, test, generate);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final b = context.block;
    final result = va.newVar(b, 'String', null);
    context.result = result;
    final start = context.addVariable(b, va, m.pos);
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context);
    addIfVar(b, m.success, (b) {
      final substring = Variable('substring');
      final callSubstring = mbrCallOp(
          varOp(m.text), varOp(substring), [varOp(start), varOp(m.pos)]);
      addAssign(b, varOp(result), callSubstring);
    });

    context.restoreVariables(b);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final b = context.block;
    final ranges = node.ranges;
    final groups = ranges.groups;
    Variable result;
    if (groups.length <= 20) {
      var hasLongChars = false;
      for (final group in groups) {
        if (group.start > 0xffff || group.end > 0xffff) {
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

      final c = context.getAlias(m.c);
      testRanges(b, c, ranges, false, generate);
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

    context.result = result;
  }

  ProductionRulesGeneratorContext visitChild(Expression expression,
      BlockOperation block, ProductionRulesGeneratorContext context,
      {bool copyAliases = true}) {
    final next = context.copy(block, copyAliases: copyAliases);
    final prev = this.context;
    this.context = next;
    expression.accept(this);
    if (next.result == null) {
      throw StateError('Variable is not defined');
    }

    this.context = prev;
    return next;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final b = context.block;
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

      final c = context.getAlias(m.c);
      final ranges = SparseBoolList();
      final group = GroupedRangeList(rune, rune, true);
      ranges.addGroup(group);
      testRanges(b, c, ranges, false, generate);
    } else if (runes.length > 1) {
      final rune = runes.first;
      result = va.newVar(b, 'String', null);

      void generate(BlockOperation b) {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        addAssign(b, varOp(result), matchString);
      }

      final c = context.getAlias(m.c);
      final ranges = SparseBoolList();
      final group = GroupedRangeList(rune, rune, true);
      ranges.addGroup(group);
      testRanges(b, c, ranges, false, generate);
    } else {
      result = va.newVar(b, 'final', constOp(''));
      addAssign(b, varOp(m.success), constOp(true));
    }

    context.result = result;
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, m.c);
    context.saveVariable(b, va, m.pos);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context);
    addAssign(b, varOp(m.success), notOp(varOp(m.success)));
    context.restoreVariables(b);
    context.result = va.newVar(b, 'var', null);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    context.result = result;
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    final passed = va.newVar(b, 'var', constOp(false));
    addLoop(b, (b) {
      final child = node.expression;
      final next = visitChild(child, b, context, copyAliases: false);
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
  }

  @override
  void visitOptional(OptionalExpression node) {
    final b = context.block;
    final child = node.expression;
    final next = visitChild(child, b, context);
    final result = va.newVar(b, 'final', varOp(next.result));
    context.result = result;
    var cannotOptimize = true;
    if (!node.isLast || child.isOptional) {
      cannotOptimize = false;
    }

    if (cannotOptimize) {
      addAssign(b, varOp(m.success), constOp(true));
    }
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
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
      final next = visitChild(child, b, context);
      addIfNotVar(b, m.success, (b) {
        addAssign(b, varOp(m.success), constOp(true));
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
}
