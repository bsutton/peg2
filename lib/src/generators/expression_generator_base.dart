import 'package:peg2/src/generators/if_else_generator.dart';
import 'package:peg2/src/generators/production_rule_name_generator.dart';
import 'package:peg2/src/helpers/null_check_helper.dart';

import '../../expressions.dart';
import '../../grammar.dart';
import '../helpers/expression_helper.dart';
import 'action_code_generator.dart';
import 'bit_flag_generator.dart';
import 'class_members.dart';
import 'code_block.dart';
import 'expression_generator.dart';
import 'members.dart';

abstract class ExpressionsGeneratorBase
    extends ExpressionVisitor<ExpressionGenerator> {
  final BitFlagGenerator failures;

  final ClassMembers members;

  final bool optimize;

  ExpressionsGeneratorBase(
      {required this.failures, required this.members, required this.optimize});

  ExpressionGenerator acceptChild(Expression node, ExpressionGenerator parent) {
    final generator = node.accept(this);
    generator.allocator = parent.allocator;
    return generator;
  }

  void generatePostCode(
      ExpressionGenerator generator,
      CodeBlock block,
      void Function(CodeBlock block)? success,
      void Function(CodeBlock block)? fail) {
    final successBlock = generator.success;
    final failBlock = generator.fail;
    if (successBlock != null && success != null) {
      success(successBlock);
      success = null;
    }

    if (failBlock != null && fail != null) {
      fail(failBlock);
      fail = null;
    }

    if (success != null || fail != null) {
      final ifElse = IfElseGenerator(ref(Members.ok));
      if (success != null) {
        ifElse.ifCode(success);
      }

      if (fail != null) {
        ifElse.elseCode(fail);
      }

      block.addLazyCode(() => ifElse.generate().code);
    }
  }

  ExpressionGenerator generateSequence(
      SequenceExpression node, int startIndex) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final expressions = node.expressions;
      final localVariables = <String?>[];
      final semanticVariables = <String?>[];
      final types = <String>[];
      final generators = <ExpressionGenerator>[];
      final active = expressions.where((e) => e.variable != null);
      var activeIndex = -1;
      if (node.actionSource == null) {
        if (active.isEmpty) {
          activeIndex = 0;
        } else if (active.length == 1) {
          activeIndex = active.first.index!;
        }
      }

      var succesBlock = block;
      for (var i = 0; i < expressions.length; i++) {
        final child = expressions[i];
        final g1 = acceptChild(child, g);
        generators.add(g1);
        if (i == 0) {
          g1.addVariables(g);
        }

        if (i == activeIndex) {
          if (child.resultUsed) {
            g1.variable = g.variable;
            g1.isVariableDeclared = g.isVariableDeclared;
          }
        }

        if (i > 0 && !expressions[i - 1].isOptional) {
          succesBlock.if$(ref(Members.ok), (block) {
            succesBlock = block;
            g1.generate(block);
          });
        } else {
          g1.generate(succesBlock);
        }

        localVariables.add(g1.variable);
        semanticVariables.add(child.variable);
        types.add(child.resultType);
      }

      generateSequenceAction(node, succesBlock, g,
          localVariables: localVariables,
          semanticVariables: semanticVariables,
          types: types);
    };

    return g;
  }

  void generateSequenceAction(
      SequenceExpression node, CodeBlock block, ExpressionGenerator generator,
      {required List<String?> localVariables,
      required List<String?> semanticVariables,
      required List<String> types}) {
    final expressions = node.expressions;
    if (generator.variable != null || node.actionIndex != null) {
      final errors = <String>[];
      void action(CodeBlock block) {
        final actionCodeGenerator = ActionCodeGenerator(
          block: block,
          actionSource: node.actionSource,
          localVariables: localVariables,
          resultType: node.resultType,
          semanticVariables: semanticVariables,
          types: types,
          variable: generator.variable,
        );
        actionCodeGenerator.generate(errors);
        if (errors.isNotEmpty) {
          final message = 'Error generating result for expression: $node';
          throw StateError(message);
        }
      }

      if (expressions.last.isOptional) {
        action(block);
        generator.success = block;
      } else {
        final ifElse = IfElseGenerator(ref(Members.ok));
        ifElse.ifCode(action);
        block.addLazyCode(() => ifElse.generate().code);
        //block.if$(ref(Members.ok), (block) {
        //  action(block);
        //  generator.success = block;
        //});
      }
    }
  }

  @override
  ExpressionGenerator visitAndPredicate(AndPredicateExpression node) {
    return _visitPrefix(node);
  }

  @override
  ExpressionGenerator visitAnyCharacter(AnyCharacterExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.allocateVariable();
      final call = callExpression(Members.matchAny);
      if (g.isVariableDeclared) {
        block.assign(g.variable!, call);
      } else {
        block.callAndTryAssignFinal(g.variable, call);
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitCapture(CaptureExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final child = node.expression;
      if (g.variable == null) {
        final g1 = acceptChild(child, g);
        g1.addVariables(g);
        g1.generate(block);
      } else {
        final start = g.store(block, Members.pos);
        final g1 = acceptChild(child, g);
        g1.addVariables(g);
        g1.generate(block);
        block.if$(ref(Members.ok), (block) {
          final args = [ref(start), ref(Members.pos)];
          final call =
              methodCallExpression(ref(Members.source), 'substring', args);
          block.assign(g.variable!, call);
        });
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitCharacterClass(CharacterClassExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.allocateVariable();
      final ranges = <int>[];
      for (final group in node.ranges.groups) {
        ranges.add(group.start);
        ranges.add(group.end);
      }

      if (ranges.length == 2) {
        if (ranges[0] == ranges[1]) {
          final char = ranges[0];
          final args = [literal(char), literal(char)];
          final call = callExpression(Members.matchChar, args);
          if (g.isVariableDeclared) {
            block.assign(g.variable!, call);
          } else {
            block.callAndTryAssignFinal(g.variable, call);
          }
        } else {
          final start = ranges[0];
          final end = ranges[1];
          final args = [literal(start), literal(end)];
          final call = callExpression(Members.matchRange, args);
          if (g.isVariableDeclared) {
            block.assign(g.variable!, call);
          } else {
            block.callAndTryAssignFinal(g.variable, call);
          }
        }
      } else {
        final range = g.allocate();
        block.assignConst(range, literalList(ranges));
        final args = [ref(range)];
        final call = callExpression(Members.matchRanges, args);
        if (g.isVariableDeclared) {
          block.assign(g.variable!, call);
        } else {
          block.callAndTryAssignFinal(g.variable, call);
        }
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitLiteral(LiteralExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.allocateVariable();
      final text = node.text;
      if (text.isEmpty) {
        g.declareVariable(block);
        block.tryAssign(g.variable, () => ref(''));
        block.assign(Members.ok, true$);
      } else if (text.length == 1) {
        final char = text.codeUnitAt(0);
        final args = [literal(char), literalString(text)];
        final call = callExpression(Members.matchChar, args);
        if (g.isVariableDeclared) {
          block.assign(g.variable!, call);
        } else {
          block.callAndTryAssignFinal(g.variable, call);
        }
      } else {
        final args = [literalString(text)];
        final call = callExpression(Members.matchString, args);
        if (g.isVariableDeclared) {
          block.assign(g.variable!, call);
        } else {
          block.callAndTryAssignFinal(g.variable, call);
        }
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitNonterminal(NonterminalExpression node) {
    return _visitSymbol(node);
  }

  @override
  ExpressionGenerator visitNotPredicate(NotPredicateExpression node) {
    return _visitPrefix(node);
  }

  @override
  ExpressionGenerator visitOneOrMore(OneOrMoreExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final child = node.expression;
      g.variables = {};
      if (g.variable == null) {
        final count = g.allocate();
        block.assignVar(count, literal(0));
        block.doWhile$(ref(Members.ok), (block) {
          final g1 = acceptChild(child, g);
          g1.generate(block);
          final inc = postfixExpression(ref(count), '++');
          block.addStatement(inc);
        });

        block.assign(Members.ok, ref(count).notEqualTo(literal(1)));
      } else {
        void fail(CodeBlock block) {
          block.break$();
        }

        final init = literalList([], ref(child.resultType));
        final list = g.allocate();
        block.assignFinal(list, init);
        block.while$(true$, (block) {
          final g1 = acceptChild(child, g);
          g1.generate(block);
          generatePostCode(g1, block, null, fail);
          final element = nullCheck(ref(g1.variable!), child.resultType);
          final args = [element];
          final call = methodCallExpression(ref(list), 'add', args);
          block.addStatement(call);
        });

        final control = ref(list).property('isNotEmpty');
        block.if$(control, (block) {
          block.assign(g.variable!, ref(list));
          block.assign(Members.ok, true$);
        });
      }
    };

    return g;
  }

  @override
  ExpressionGenerator visitOptional(OptionalExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.allocateVariable();
      final child = node.expression;
      final g1 = acceptChild(child, g);
      g1.addVariables(g);
      g1.variable = g.variable;
      g1.generate(block);
      block.assign(Members.ok, true$);
    };

    return g;
  }

  @override
  ExpressionGenerator visitSubterminal(SubterminalExpression node) {
    return _visitSymbol(node);
  }

  @override
  ExpressionGenerator visitTerminal(TerminalExpression node) {
    return _visitSymbol(node);
  }

  @override
  ExpressionGenerator visitZeroOrMore(ZeroOrMoreExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final child = node.expression;
      g.variables = {};
      if (g.variable == null) {
        block.doWhile$(ref(Members.ok), (block) {
          final g1 = acceptChild(child, g);
          g1.generate(block);
        });

        block.assign(Members.ok, true$);
      } else {
        void fail(CodeBlock block) {
          block.break$();
        }

        final init = literalList([], ref(child.resultType));
        final list = g.allocate();
        block.assignFinal(list, init);
        block.while$(true$, (block) {
          final g1 = acceptChild(child, g);
          g1.generate(block);
          generatePostCode(g1, block, null, fail);
          final element = nullCheck(ref(g1.variable!), child.resultType);
          final args = [element];
          final call = methodCallExpression(ref(list), 'add', args);
          block.addStatement(call);
        });

        block.if$(ref(Members.ok).assign(true$), (block) {
          block.assign(g.variable!, ref(list));
        });
      }
    };

    return g;
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

  ExpressionGenerator _visitPrefix(PrefixExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.declareVariable(block);
      final rule = node.rule!;
      final child = node.expression;
      final isNotPredicate = node.kind == ExpressionKind.notPredicate;
      final childKind = child.kind;
      var test = false$;
      if (childKind == ExpressionKind.anyCharacter) {
        if (isNotPredicate) {
          test = ref(Members.ch).equalTo(literal(Expression.eof));
        } else {
          test = ref(Members.ch).notEqualTo(literal(Expression.eof));
        }
      } else if (childKind == ExpressionKind.characterClass) {
        final ranges = (child as CharacterClassExpression).ranges;
        if (ranges.groupCount == 1) {
          final group = ranges.groups.first;
          final start = group.start;
          final end = group.end;
          if (start == end) {
            if (isNotPredicate) {
              test = ref(Members.ch).notEqualTo(literal(start));
            } else {
              test = ref(Members.ch).equalTo(literal(start));
            }
          }
        }
      } else if (childKind == ExpressionKind.literal) {
        final text = (child as LiteralExpression).text;
        final args = [literalString(text), ref(Members.pos)];
        test = methodCallExpression(ref(Members.source), 'startsWith', args);
        if (isNotPredicate) {
          test = test.negate();
        }
      }

      if (test != false$) {
        block.assign(Members.ok, test);
      } else {
        g.store(block, Members.ch);
        g.store(block, Members.pos);
        g.store(block, Members.failPos);
        if (rule.kind == ProductionRuleKind.nonterminal) {
          g.store(block, Members.failStart);
          for (final variable in failures.variables) {
            g.store(block, variable);
          }
        }

        final g1 = acceptChild(child, g);
        g1.addVariables(g);
        g1.generate(block);
        g.restoreAll(block);
        if (node.kind == ExpressionKind.notPredicate) {
          block.assign(Members.ok, ref(Members.ok).negate());
        }
      }
    };

    return g;
  }

  ExpressionGenerator _visitSymbol(SymbolExpression node) {
    final g = ExpressionGenerator(node);
    g.generate = (block) {
      g.allocateVariable();
      final rule = node.expression!.rule!;
      final nameGenerator = ProductionRuleNameGenerator();
      final identifier = nameGenerator.generate(rule);
      final call = callExpression(identifier);
      if (g.isVariableDeclared) {
        block.assign(g.variable!, call);
      } else {
        block.callAndTryAssignFinal(g.variable, call);
      }
    };

    return g;
  }
}
