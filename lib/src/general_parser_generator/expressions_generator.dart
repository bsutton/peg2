part of '../../general_parser_generator.dart';

class ExpressionsGenerator extends ExpressionsGeneratorBase {
  ExpressionsGenerator(
      {required BitFlagGenerator failures,
      required ClassMembers members,
      required bool optimize})
      : super(failures: failures, members: members, optimize: optimize);

  @override
  ExpressionGenerator visitOrderedChoice(OrderedChoiceExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final rule = node.rule!;
      final level = node.level;
      final expressions = node.expressions;
      void failure(CodeBlock block) {
        if (rule.kind == ProductionRuleKind.terminal &&
            level == 0 &&
            !node.isOptional) {
          final args = [literalString(rule.name)];
          final control = callExpression(Members.fail, args);
          block.if$(control, (code) {
            final terminalId = rule.terminalId;
            final setFlag = failures.generateSet(true, [terminalId]);
            block.addSourceCode(setFlag.join('\n'));
          });
        }
      }

      if (rule.kind == ProductionRuleKind.terminal &&
          level == 0 &&
          !node.isOptional) {
        block.assign(Members.failPos, ref(Members.pos));
      }

      if (expressions.length > 1) {
        _generateOrderedChoiceMultiple(node, block, g, failure);
      } else {
        _generateOrderedChoiceSingle(node, block, g, failure);
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitSequence(SequenceExpression node) {
    return generateSequence(node, 0);
  }

  void _generateOrderedChoiceMultiple(
      OrderedChoiceExpression node,
      CodeBlock block,
      ExpressionGenerator g,
      void Function(CodeBlock block) failure) {
    final expressions = node.expressions;
    final isTopLevel = node.level == 0;
    final charChanges = <bool>[];
    final posChanges = <bool>[];
    void addReturn(CodeBlock block) {
      if (g.variable == null) {
        block.addStatement(null$.returned);
      } else {
        block.addStatement(ref(g.variable!).returned);
      }
    }

    void addBreakOrReturn(CodeBlock block) {
      if (isTopLevel) {
        addReturn(block);
      } else {
        block.break$();
      }
    }

    void success(CodeBlock block) {
      addBreakOrReturn(block);
    }

    void body(CodeBlock block) {
      for (var i = 0; i < expressions.length; i++) {
        final child = expressions[i];
        final g1 = acceptChild(child, g);
        g1.variable = g.variable;
        g1.isVariableDeclared = g.isVariableDeclared;
        g1.addVariables(g);
        g1.generate(block);
        generatePostCode(g1, block, success, null);
        if (charChanges[i]) {
          g.restore(block, Members.ch);
        }

        if (posChanges[i]) {
          g.restore(block, Members.pos);
        }
      }

      if (!isTopLevel) {
        block.break$();
      }
    }

    for (final child in expressions) {
      final willChangeChar = willExpressionChangeCharOnFailure(child, {});
      final willChangePos = willSequenceChangePosOnFailure(child);
      charChanges.add(willChangeChar);
      posChanges.add(willChangePos);
    }

    if (charChanges.where((e) => e).isNotEmpty) {
      g.store(block, Members.ch);
    }

    if (posChanges.where((e) => e).isNotEmpty) {
      g.store(block, Members.pos);
    }

    if (isTopLevel) {
      body(block);
    } else {
      block.while$(true$, body);
    }

    failure(block);
    if (isTopLevel) {
      addReturn(block);
    }
  }

  void _generateOrderedChoiceSingle(
      OrderedChoiceExpression node,
      CodeBlock block,
      ExpressionGenerator g,
      void Function(CodeBlock block) failure) {
    void fail(CodeBlock block) {
      g.restoreAll(block);
      failure(block);
      g.fail = block;
    }

    final child = node.expressions[0];
    final needSavePos = willSequenceChangePosOnFailure(child);
    final needSaveChar = willExpressionChangeCharOnFailure(child, {});
    if (needSaveChar) {
      g.store(block, Members.ch);
    }

    if (needSavePos) {
      g.store(block, Members.pos);
    }

    final g1 = acceptChild(child, g);
    g1.variable = g.variable;
    g1.isVariableDeclared = g.isVariableDeclared;
    g1.addVariables(g);
    g1.generate(block);
    generatePostCode(g1, block, null, fail);
    if (node.level == 0) {
      if (g.variable == null) {
        block.addStatement(null$.returned);
      } else {
        block.addStatement(ref(g.variable!).returned);
      }
    }
  }
}
