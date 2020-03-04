part of '../../common_generators.dart';

abstract class ExpressionsToOperationsGenerator<M extends ParserClassMembers>
    extends ExpressionVisitor with OperationUtils {
  List<ProductionRulesGeneratorContext> contexts = [];

  final M m;

  final String parameterCallerId = 'parameterCallerId';

  final String parameterProductive = 'parameterProductive';

  VariableAllocator va;

  ExpressionsToOperationsGenerator(this.m);

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
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, m.c);
    context.saveVariable(b, va, m.pos);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context, [m.c, m.pos]);
    context.restoreVariables(b);
    context.result = va.newVar(b, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final context = contexts.last;
    final b = context.block;
    final result = va.newVar(b, 'int', null);
    context.result = result;
    var c = context.tryGetVariable(m.c);
    c ??= m.c;
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
    final context = contexts.last;
    final b = context.block;
    final result = va.newVar(b, 'String', null);
    context.result = result;
    final start = context.addVariable(b, va, m.pos);
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context, [m.c, m.pos]);
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
    final context = contexts.last;
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

      var c = context.tryGetVariable(m.c);
      c ??= m.c;
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

  @override
  void visitLiteral(LiteralExpression node) {
    final context = contexts.last;
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

      var c = context.tryGetVariable(m.c);
      c ??= m.c;
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

      var c = context.tryGetVariable(m.c);
      c ??= m.c;
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
    final context = contexts.last;
    final b = context.block;
    final productive = context.getArgument(parameterProductive);
    context.saveVariable(b, va, m.c);
    context.saveVariable(b, va, m.pos);
    context.saveVariable(b, va, productive);
    addAssign(b, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, b, context, [m.c, m.pos]);
    addAssign(b, varOp(m.success), notOp(varOp(m.success)));
    context.restoreVariables(b);
    context.result = va.newVar(b, 'var', null);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final context = contexts.last;
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
      final next = visitChild(child, b, context);
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
    final context = contexts.last;
    final b = context.block;
    final child = node.expression;
    final next = visitChild(child, b, context);
    context.result = next.result;
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
    final context = contexts.last;
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
