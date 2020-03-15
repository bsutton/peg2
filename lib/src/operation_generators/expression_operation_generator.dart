part of '../../operation_generators.dart';

abstract class ExpressionOperationGenerator
    extends ExpressionOperationGeneratorBase {
  ExpressionOperationGenerator(ParserGeneratorOptions options,
      BlockOperation block, VariableAllocator va)
      : super(options, block, va);

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final session = getSession();
    saveVariable(session, m.c);
    saveVariable(session, m.pos);
    saveVariable(session, m.error);
    saveVariable(session, m.expected);
    saveVariable(session, m.failure);
    saveVariable(session, productive);
    addAssign(block, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, block);
    restoreVariables(session);
    result = va.newVar(block, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    result = va.newVar(block, 'int', null);
    final ranges = SparseBoolList();
    final group = GroupedRangeList<bool>(0, 0x10ffff, true);
    ranges.addGroup(group);
    void onSuccess(BlockOperation block) {
      addAssign(block, varOp(m.success), constOp(true));
      if (isProductive) {
        addAssign(block, varOp(result), varOp(m.c));
      }

      final nextCharGenerator = NextCharGenerator();
      nextCharGenerator.generate(block, ranges,
          c: m.c, input: m.input, pos: m.pos);
    }

    void onFail(BlockOperation block) {
      addAssign(block, varOp(m.success), constOp(false));
      addAssign(block, varOp(m.failure), varOp(m.pos));
    }

    final rangesOperationGenerator = RangesOperationGenerator();
    rangesOperationGenerator.generateConditional(
        block, m.c, ranges, false, onSuccess, onFail);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final session = getSession();
    final result1 = va.newVar(block, 'String', null);
    final start = va.newVar(block, 'final', varOp(m.pos));
    saveVariable(session, productive);
    addAssign(block, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, block);
    if (isProductive) {
      addIfVar(block, m.success, (block) {
        final substring = Variable('substring');
        final call = mbrCallOp(
            varOp(m.text), varOp(substring), [varOp(start), varOp(m.pos)]);
        addAssign(block, varOp(result1), call);
      });
    }

    restoreVariables(session);
    result = result1;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final ranges = node.ranges;
    final groups = ranges.groups;
    Variable result1;
    if (groups.length <= 20) {
      result1 = va.newVar(block, 'int', null);

      void onSuccess(BlockOperation block) {
        addAssign(block, varOp(m.success), constOp(true));
        if (isProductive) {
          addAssign(block, varOp(result1), varOp(m.c));
        }

        final nextCharGenerator = NextCharGenerator();
        nextCharGenerator.generate(block, ranges,
            c: m.c, input: m.input, pos: m.pos);
      }

      void onFail(BlockOperation block) {
        addAssign(block, varOp(m.success), constOp(false));
        addAssign(block, varOp(m.failure), varOp(m.pos));
      }

      final rangesOperationGenerator = RangesOperationGenerator();
      rangesOperationGenerator.generateConditional(
          block, m.c, ranges, false, onSuccess, onFail);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(constOp(ranges[i]));
        elements.add(constOp(ranges[i + 1]));
      }

      final list = listOp(null, elements);
      final chars = va.newVar(block, 'const', list);
      final matchRanges = callOp(varOp(m.matchRanges), [varOp(chars)]);
      result1 = va.newVar(block, 'final', matchRanges);
    }

    result = result1;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    final runes = text.runes;
    Variable result1;
    if (runes.length == 1) {
      final rune = runes.first;
      result1 = va.newVar(block, 'String', null);
      final ranges = SparseBoolList();
      final group = GroupedRangeList<bool>(rune, rune, true);
      ranges.addGroup(group);

      void onSuccess(BlockOperation block) {
        addAssign(block, varOp(m.success), constOp(true));
        if (isProductive) {
          addAssign(block, varOp(result1), constOp(text));
        }

        final nextCharGenerator = NextCharGenerator();
        nextCharGenerator.generate(block, ranges,
            c: m.c, input: m.input, pos: m.pos);
      }

      void onFail(BlockOperation block) {
        addAssign(block, varOp(m.success), constOp(false));
        addAssign(block, varOp(m.failure), varOp(m.pos));
      }

      final rangesOperationGenerator = RangesOperationGenerator();
      rangesOperationGenerator.generateConditional(
          block, m.c, ranges, false, onSuccess, onFail);
    } else if (runes.length > 1) {
      final rune = runes.first;
      result1 = va.newVar(block, 'String', null);
      final ranges = SparseBoolList();
      final group = GroupedRangeList<bool>(rune, rune, true);
      ranges.addGroup(group);

      void onSuccess(BlockOperation block) {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        addAssign(block, varOp(result1), matchString);
      }

      void onFail(BlockOperation block) {
        addAssign(block, varOp(m.success), constOp(false));
        addAssign(block, varOp(m.failure), varOp(m.pos));
      }

      final rangesOperationGenerator = RangesOperationGenerator();
      rangesOperationGenerator.generateConditional(
          block, m.c, ranges, false, onSuccess, onFail);
    } else {
      result1 = va.newVar(block, 'final', constOp(''));
      addAssign(block, varOp(m.success), constOp(true));
    }

    result = result1;
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final session = getSession();
    saveVariable(session, m.c);
    saveVariable(session, m.pos);
    saveVariable(session, m.error);
    saveVariable(session, m.expected);
    saveVariable(session, m.failure);
    saveVariable(session, productive);
    addAssign(block, varOp(productive), constOp(false));
    final child = node.expression;
    visitChild(child, block);
    addAssign(block, varOp(m.success), notOp(varOp(m.success)));
    restoreVariables(session);
    result = va.newVar(block, 'var', null);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final returnType = node.returnType;
    final result1 = va.newVar(block, returnType, null);
    if (isProductive) {
      addIfVar(block, productive, (block) {
        addAssign(block, varOp(result1), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    final passed = va.newVar(block, 'var', constOp(false));
    addLoop(block, (block) {
      final child = node.expression;
      visitChild(child, block);
      addIfNotVar(block, m.success, (block) {
        addAssign(block, varOp(m.success), varOp(passed));
        addIfNotVar(block, m.success, (block) {
          addAssign(block, varOp(result1), constOp(null));
        });

        addBreak(block);
      });

      if (isProductive) {
        addIfVar(block, productive, (block) {
          final add = Variable('add');
          addMbrCall(block, varOp(result1), varOp(add), [varOp(result)]);
        });
      } else {
        // Do nothing
      }

      addAssign(block, varOp(passed), constOp(true));
    });

    result = result1;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    visitChild(child, block);
    result = va.newVar(block, 'final', varOp(result));
    var cannotOptimize = true;
    if (!node.isLast || child.isOptional) {
      cannotOptimize = false;
    }

    if (cannotOptimize) {
      addAssign(block, varOp(m.success), constOp(true));
    }
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final returnType = node.returnType;
    final result1 = va.newVar(block, returnType, null);
    if (isProductive) {
      addIfVar(block, productive, (block) {
        addAssign(block, varOp(result1), listOp(null, []));
      });
    } else {
      // Do nothing
    }

    addLoop(block, (block) {
      final child = node.expression;
      visitChild(child, block);
      addIfNotVar(block, m.success, (block) {
        addAssign(block, varOp(m.success), constOp(true));
        addBreak(block);
      });
      if (isProductive) {
        addIfVar(block, productive, (block) {
          final add = Variable('add');
          addMbrCall(block, varOp(result1), varOp(add), [varOp(result)]);
        });
      } else {
        // Do nothing
      }
    });

    result = result1;
  }
}
