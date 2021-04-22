part of '../../matcher_generators.dart';

class OrderedChoiceGenerator extends MatcherGenerator<OrderedChoiceMatcher> {
  final BitFlagGenerator failures;

  OrderedChoiceGenerator(OrderedChoiceMatcher matcher, this.failures)
      : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    final expression = matcher.expression;
    final rule = expression.rule!;
    final level = expression.level;
    final expressions = expression.expressions;
    void failure(CodeBlock block) {
      if (rule.kind == ProductionRuleKind.terminal &&
          level == 0 &&
          !expression.isOptional) {
        final args = [literalString(rule.name)];
        final control = callExpression(Members.fail, args);
        block.if$(control, (block) {
          final terminalId = rule.terminalId;
          final setFlag = failures.generateSet(true, [terminalId]);
          block.addSourceCode(setFlag.join('\n'));
        });
      }
    }

    if (expressions.length > 1) {
      _generateOrderedChoiceMultiple(block, accept, failure);
    } else {
      _generateOrderedChoiceSingle(block, accept, failure);
    }
  }

  void _generateOrderedChoiceMultiple(CodeBlock block,
      MatcherGeneratorAccept accept, void Function(CodeBlock block) failure) {
    final matchers = matcher.matchers;
    final expression = matcher.expression;
    final isTopLevel = expression.level == 0;
    final charChanges = <bool>[];
    final posChanges = <bool>[];
    void addReturn(CodeBlock block) {
      if (variable == null) {
        block.addStatement(null$.returned);
      } else {
        block.addStatement(ref(variable!).returned);
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
      for (var i = 0; i < matchers.length; i++) {
        final child = matchers[i];
        final generator = accept(child, this);
        generator.variable = variable;
        generator.isVariableDeclared = isVariableDeclared;
        generator.addVariables(this);
        generator.generate(block, accept);
        generatePostCode(generator, block, success, null);
        if (charChanges[i]) {
          restore(block, Members.ch);
        }

        if (posChanges[i]) {
          restore(block, Members.pos);
        }
      }

      if (!isTopLevel) {
        block.break$();
      }
    }

    for (final child in matchers) {
      final willChangeChar =
          willExpressionChangeCharOnFailure(child.expression, {});
      final willChangePos = willSequenceChangePosOnFailure(
          child.expression as SequenceExpression);
      charChanges.add(willChangeChar);
      posChanges.add(willChangePos);
    }

    if (charChanges.where((e) => e).isNotEmpty) {
      store(block, Members.ch);
    }

    if (posChanges.where((e) => e).isNotEmpty) {
      store(block, Members.pos);
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

  void _generateOrderedChoiceSingle(CodeBlock block,
      MatcherGeneratorAccept accept, void Function(CodeBlock block) failure) {
    void fail(CodeBlock block) {
      restoreAll(block);
      failure(block);
      this.fail = block;
    }

    final expression = matcher.expression;
    final matchers = matcher.matchers;
    final child = matchers[0];
    final needSavePos =
        willSequenceChangePosOnFailure(child.expression as SequenceExpression);
    final needSaveChar =
        willExpressionChangeCharOnFailure(child.expression, {});
    if (needSaveChar) {
      store(block, Members.ch);
    }

    if (needSavePos) {
      store(block, Members.pos);
    }

    final generator = accept(child, this);
    generator.variable = variable;
    generator.isVariableDeclared = isVariableDeclared;
    generator.addVariables(this);
    generator.generate(block, accept);
    generatePostCode(generator, block, null, fail);
    if (expression.level == 0) {
      if (variable == null) {
        block.addStatement(null$.returned);
      } else {
        block.addStatement(ref(variable!).returned);
      }
    }
  }

  bool willExpressionChangeCharOnFailure(
      Expression node, Set<Expression> processed) {
    if (!processed.add(node)) {
      return true;
    }

    switch (node.kind) {
      case ExpressionKind.andPredicate:
      case ExpressionKind.anyCharacter:
      case ExpressionKind.characterClass:
      case ExpressionKind.literal:
      case ExpressionKind.notPredicate:
        return false;
      case ExpressionKind.capture:
      case ExpressionKind.optional:
      case ExpressionKind.oneOrMore:
      case ExpressionKind.zeroOrMore:
        final single = node as SingleExpression;
        return willExpressionChangeCharOnFailure(single.expression, processed);
      case ExpressionKind.nonterminal:
      case ExpressionKind.subterminal:
      case ExpressionKind.terminal:
        final symbol = node as SymbolExpression;
        return willExpressionChangeCharOnFailure(symbol.expression!, processed);
      case ExpressionKind.orderedChoice:
        final choice = node as OrderedChoiceExpression;
        final expressions = choice.expressions;
        for (final expression in expressions) {
          if (willExpressionChangeCharOnFailure(expression, processed)) {
            return true;
          }
        }

        return false;
      case ExpressionKind.sequence:
        final sequence = node as SequenceExpression;
        final expressions = sequence.expressions;
        var count = 0;
        var skipOtional = false;
        for (final expression in expressions) {
          switch (expression.kind) {
            case ExpressionKind.andPredicate:
            case ExpressionKind.notPredicate:
              continue;
            default:
          }

          if (expression.isOptional && skipOtional) {
            continue;
          }

          if (count > 0) {
            return true;
          }

          skipOtional = true;
          count++;
        }

        return false;
    }
  }

  bool willSequenceChangePosOnFailure(SequenceExpression node) {
    var count = 0;
    for (final child in node.expressions) {
      switch (child.kind) {
        case ExpressionKind.andPredicate:
        case ExpressionKind.notPredicate:
          continue;
        default:
      }

      if (child.isOptional) {
        if (count == 0) {
          count++;
        }

        continue;
      }

      if (count++ > 0) {
        return true;
      }
    }

    return false;
  }
}
