part of '../../postfix_parser_generator.dart';

class PostfixExpressionOperationGenerator0 extends ExpressionOperationGenerator
    with PostfixProductionRuleUtils {
  Variable startPos;

  //final Map<SequenceExpression, Variable> _sequenceMethodVariables = {};

  PostfixExpressionOperationGenerator0(ParserGeneratorOptions options,
      BlockOperation block, VariableAllocator va)
      : super(options, block, va);

  @override
  void visitNonterminal(NonterminalExpression node) {
    // TODO: implement visitNonterminal
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final session = getSession();
    final c = saveVariable(session, m.c);
    final pos = saveVariable(session, m.pos);
    final isOnTop = node.parent == null;
    startPos = pos;
    final expressionChainResolver = ExpressionChainResolver();
    final root = expressionChainResolver.resolve(node);
    final choices = _flattenNode(root);
    final transitions = SparseList<List<int>>();
    final epsilons = <int>[];
    _computeTransitions(choices, transitions, epsilons);
    final startCharacters = node.startCharacters;
    final nextCharGenerator = NextCharGenerator();
    nextCharGenerator.generate(block, startCharacters,
        c: c, input: m.input, pos: m.pos);
    final returnType = node.returnType;
    final result1 = va.newVar(block, returnType, null);
    final generator =
        PostfixExpressionOperationGenerator1(options, block, va, c, pos);
    if (choices.length > 1) {
      addLoop(block, (block) {
        final workTransitions = SparseList<List<int>>();
        final useStates = transitions.groups.any((e) => e.key.length > 1);
        final groups = transitions.groups;
        for (var i = 0; i < groups.length; i++) {
          final src = groups[i];
          GroupedRangeList<List<int>> dest;
          if (useStates) {
            dest = GroupedRangeList<List<int>>(i, i, src.key);
          } else {
            dest = GroupedRangeList<List<int>>(src.start, src.end, src.key);
          }

          workTransitions.addGroup(dest);
        }

        Variable transitionVariable;
        if (useStates) {
          // TODO: Implement: transitionVariable = Variable('STATE');
          transitionVariable = Variable('STATE');
          throw UnimplementedError();
        } else {
          transitionVariable = c;
        }

        for (final transition in workTransitions.groups) {
          final ranges = SparseBoolList();
          final group =
              GroupedRangeList<bool>(transition.start, transition.end, true);
          ranges.addGroup(group);
          final rangesOperationGenerator = RangesOperationGenerator();
          rangesOperationGenerator.generateConditional(
              block, transitionVariable, ranges, false, (block) {
            for (final i in transition.key) {
              final choice = choices[i];
              for (final expression in choice) {
                addAssign(block, varOp(m.success), constOp(true));
                visitChild(generator, expression, block);
                addIfVar(block, m.success, (h) {
                  addAssign(block, varOp(result1), varOp(result));
                  addBreak(block);
                });
              }
            }
          });
        }

        if (epsilons.isNotEmpty) {
          for (final i in epsilons) {
            final choice = choices[i];
            for (final expression in choice) {
              addAssign(block, varOp(m.success), constOp(true));
              visitChild(generator, expression, block);
              addIfVar(block, m.success, (h) {
                addAssign(block, varOp(result1), varOp(result));
                addBreak(block);
              });
            }
          }
        }
      });
    } else {
      final choice = choices.first;
      final rangesOperationGenerator = RangesOperationGenerator();
      rangesOperationGenerator
          .generateConditional(block, c, startCharacters, false, (block) {
        for (final expression in choice) {
          addAssign(block, varOp(m.success), constOp(true));
          visitChild(generator, expression, block);
          addIfVar(block, m.success, (h) {
            addAssign(block, varOp(result1), varOp(result));
            addBreak(block);
          });
        }
      });

      if (epsilons.isNotEmpty) {
        for (final i in epsilons) {
          final choice = choices[i];
          for (final expression in choice) {
            addAssign(block, varOp(m.success), constOp(true));
            visitChild(generator, expression, block);
            addIfVar(block, m.success, (h) {
              addAssign(block, varOp(result1), varOp(result));
              addBreak(block);
            });
          }
        }
      }
    }

    if (isOnTop) {
      addReturn(block, varOp(result1));
    }

    result = result1;
  }

  @override
  void visitSequence(SequenceExpression node) {
    // TODO: implement visitSequence
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    // TODO: implement visitSubterminal
  }

  @override
  void visitTerminal(TerminalExpression node) {
    // TODO: implement visitTerminal
  }

  void _computeTransitions(List<List<Expression>> choices,
      SparseList<List<int>> transitions, List<int> epsilons) {
    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final first = choice.first;
      for (final src in first.startCharacters.getGroups()) {
        final allSpace = transitions.getAllSpace(src);
        for (final dest in allSpace) {
          var key = dest.key;
          if (key == null) {
            key = [i];
          } else {
            key.add(i);
          }

          final group = GroupedRangeList<List<int>>(dest.start, dest.end, key);
          transitions.addGroup(group);
        }
      }
    }

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final last = choice.last;
      if (last.canMacthEof) {
        epsilons.add(i);
      }
    }
  }

  List<List<Expression>> _flattenNode(ExpressionNode node) {
    final result = <List<Expression>>[];
    if (node.children.isEmpty) {
      result.add([node.expression]);
    } else {
      for (final child in node.children) {
        final branch = _flattenNode(child);
        for (var element in branch) {
          element.add(node.expression);
          result.add(element);
        }
      }
    }

    return result;
  }
}
