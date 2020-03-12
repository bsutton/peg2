part of '../../postfix_parser_generator.dart';

class PostfixExpressionOperationGenerator extends ExpressionOperationGenerator
    with PostfixProductionRuleUtils {
  Set<ProductionRule> calledRules = {};

  bool canMatchEof;

  int mode;

  Variable pos;

  final Map<SequenceExpression, MethodOperation> _methods = {};

  PostfixExpressionOperationGenerator(ParserGeneratorOptions options,
      BlockOperation block, VariableAllocator va)
      : super(options, block, va);

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    if (mode == 0) {
      final result1 = va.newVar(block, 'final', constOp(null));
      result = result1;
    } else {
      super.visitAndPredicate(node);
    }
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    if (mode == 0 && !canMatchEof) {
      Variable result1;
      if (isProductive) {
        result1 = va.newVar(block, 'final', varOp(m.c));
      } else {
        result1 = va.newVar(block, 'int', null);
      }

      addAssign(block, varOp(m.success), constOp(true));
      final ranges = SparseBoolList();
      final group = GroupedRangeList<bool>(0, 0x10ffff, true);
      ranges.addGroup(group);
      final nextCharGenerator = NextCharGenerator();
      nextCharGenerator.generate(block, ranges,
          c: m.c, input: m.input, pos: m.pos);
      result = result1;
    } else {
      super.visitAnyCharacter(node);
    }
  }

  @override
  void visitCapture(CaptureExpression node) {
    if (mode == 0) {
      final substring = Variable('substring', true);
      final call = mbrCallOp(
          varOp(m.text), varOp(substring), [varOp(pos), varOp(m.pos)]);
      result = va.newVar(block, 'final', call);
    } else {
      super.visitCapture(node);
    }
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    if (mode == 0 && !canMatchEof) {
      Variable result1;
      if (isProductive) {
        result1 = va.newVar(block, 'final', varOp(m.c));
      } else {
        result1 = va.newVar(block, 'int', null);
      }

      addAssign(block, varOp(m.success), constOp(true));
      final ranges = node.startCharacters;
      final nextCharGenerator = NextCharGenerator();
      nextCharGenerator.generate(block, ranges,
          c: m.c, input: m.input, pos: m.pos);
      result = result1;
    } else {
      super.visitCharacterClass(node);
    }
  }

  @override
  void visitLiteral(LiteralExpression node) {
    if (mode == 0 && !canMatchEof) {
      Variable result1;
      final text = node.text;
      final runes = text.runes.toList();
      if (runes.isEmpty) {
        result1 = va.newVar(block, 'final', constOp(''));
        addAssign(block, varOp(m.success), constOp(true));
      } else if (runes.length == 1) {
        result1 = va.newVar(block, 'final', constOp(text));
        addAssign(block, varOp(m.success), constOp(true));
        final ranges = node.startCharacters;
        final nextCharGenerator = NextCharGenerator();
        nextCharGenerator.generate(block, ranges,
            c: m.c, input: m.input, pos: m.pos);
      } else {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        result1 = va.newVar(block, 'final', matchString);
      }

      result = result1;
    } else {
      super.visitLiteral(node);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    if (mode == 0) {
      addAssign(block, varOp(m.success), constOp(false));
      final result1 = va.newVar(block, 'final', constOp(null));
      result = result1;
    } else {
      super.visitNotPredicate(node);
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    if (mode == 0) {
      Variable result1;
      if (isProductive) {
        addIfVar(block, productive, (block) {
          final list = listOp(null, [varOp(result)]);
          result1 = va.newVar(block, 'final', list);
        });
      } else {
        final returnType = node.returnType;
        result1 = va.newVar(block, returnType, null);
      }

      addLoop(block, (block) {
        final child = node.expression;
        final mode1 = mode;
        mode = 1;
        visitChild(child, block);
        mode = mode1;
        addIfNotVar(block, m.success, addBreak);
        final add = Variable('add');
        addMbrCall(block, varOp(result1), varOp(add), [varOp(result)]);
      });

      result = result1;
    } else {
      super.visitOneOrMore(node);
    }
  }

  @override
  void visitOptional(OptionalExpression node) {
    if (mode == 0) {
      final returnType = node.returnType;
      final result1 = va.newVar(block, returnType, varOp(result));
      result = result1;
    } else {
      super.visitOptional(node);
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (mode == 0) {
      final returnType = node.returnType;
      final result1 = va.newVar(block, returnType, varOp(result));
      result = result1;
      return;
    }

    final mode1 = mode;
    mode = 0;
    final session = getSession();
    final expressions = node.expressions;
    final c = saveVariable(session, m.c);
    pos = saveVariable(session, m.pos);
    final isOnTop = node.parent == null;
    final expressionChainResolver = ExpressionChainResolver();
    final root = expressionChainResolver.resolve(node);
    final choices = _flattenNode(root);
    final states = <List<int>>[];
    final stateCharacters = <SparseBoolList>[];
    _computeTransitions(expressions, states, stateCharacters);
    final returnType = node.returnType;
    final result1 = va.newVar(block, returnType, null);
    addLoop(block, (block) {
      for (var i = 0; i < states.length; i++) {
        final state = states[i];
        final ranges = stateCharacters[i];
        final rangesOperationGenerator = RangesOperationGenerator();
        rangesOperationGenerator.generateConditional(block, c, ranges, false,
            (block) {
          for (final index in state) {
            final choice = choices[index];
            final sequence = expressions[index];
            canMatchEof = sequence.canMatchEof;

            void plunge(
                BlockOperation block, List<Expression> expressions, int index) {
              if (index >= expressions.length) {
                return;
              }

              final expression = expressions[index];
              visitChild(expression, block);
              addIfVar(block, m.success, (block) {
                plunge(block, choice, index + 1);
                if (index == expressions.length - 1) {
                  addAssign(block, varOp(result1), varOp(result));
                  addBreak(block);
                }
              });
            }

            plunge(block, choice, 0);
            addIfNotVar(block, m.success, (block) {
              addAssign(block, varOp(m.c), varOp(c));
              addAssign(block, varOp(m.pos), varOp(pos));
            });
          }
        });
      }
    });

    if (isOnTop) {
      addReturn(block, varOp(result1));
    }

    result = result1;
    mode = mode1;
  }

  @override
  void visitSequence(SequenceExpression node) {
    if (mode == 0) {
      _generateSequenceMethod(node);
      final name = getExpressionMethodName(node);
      final function = varOp(Variable(name, true));
      final arguments = <Operation>[];
      final call = callOp(function, arguments);
      final result1 = va.newVar(block, 'final', call);
      result = result1;
    } else {
      throw StateError('The sequence expression should not be called here');
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbol(node);
  }

  void _visitSymbol(SymbolExpression node) {
    final expression = node.expression;
    final rule = expression.rule;
    calledRules.add(rule);
    final arguments = <Operation>[];
    arguments.add(constOp(node.id));
    arguments.add(varOp(productive));
    final name = getExpressionMethodName(expression);
    final function = Variable(name, true);
    final call = callOp(varOp(function), arguments);
    result = va.newVar(block, 'final', call);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    if (mode == 0) {
      Variable result1;
      if (isProductive) {
        final returnType = node.returnType;
        result1 = va.newVar(block, returnType, null);
        addIfVar(block, productive, (block) {
          final list = listOp(null, [varOp(result)]);
          addAssignOp(varOp(result1), list);
        });
      } else {
        final returnType = node.returnType;
        result1 = va.newVar(block, returnType, null);
      }

      addLoop(block, (block) {
        final child = node.expression;
        final mode1 = mode;
        mode = 1;
        visitChild(child, block);
        mode = mode1;
        addIfNotVar(block, m.success, addBreak);
        final add = Variable('add');
        addMbrCall(block, varOp(result1), varOp(add), [varOp(result)]);
      });

      result = result1;
    } else {
      super.visitZeroOrMore(node);
    }
  }

  void _computeTransitions(List<SequenceExpression> sequences,
      List<List<int>> states, List<SparseBoolList> stateCharacters) {
    final statesAndCharacters = SparseList<List<int>>();
    for (var i = 0; i < sequences.length; i++) {
      final sequence = sequences[i];
      for (final src in sequence.startCharacters.getGroups()) {
        final allSpace = statesAndCharacters.getAllSpace(src);
        for (final dest in allSpace) {
          var key = dest.key;
          if (key == null) {
            key = [i];
          } else {
            key.add(i);
          }

          final group = GroupedRangeList<List<int>>(dest.start, dest.end, key);
          statesAndCharacters.addGroup(group);
        }
      }
    }

    int addState(List<int> choiceIndexes) {
      for (var i = 0; i < states.length; i++) {
        final state = states[i];
        if (choiceIndexes.length == state.length) {
          var found = true;
          for (var j = 0; j < choiceIndexes.length; j++) {
            if (choiceIndexes[j] != state[j]) {
              found = false;
              break;
            }
          }

          if (found) {
            return i;
          }
        }
      }

      states.add(choiceIndexes.toList());
      return states.length - 1;
    }

    final map = <int, List<GroupedRangeList<List<int>>>>{};
    for (final group in statesAndCharacters.groups) {
      final key = group.key;
      final i = addState(key);
      var value = map[i];
      if (value == null) {
        value = [];
        map[i] = value;
      }

      value.add(group);
    }

    stateCharacters.length = states.length;
    for (var i = 0; i < states.length; i++) {
      final groups = map[i];
      final list = SparseBoolList();
      for (final src in groups) {
        final dest = GroupedRangeList<bool>(src.start, src.end, true);
        list.addGroup(dest);
      }

      stateCharacters[i] = list;
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

  void _generateSequenceMethod(SequenceExpression node) {
    var method = _methods[node];
    if (method != null) {
      return;
    }

    final block1 = block;
    block = BlockOperation();
    final va1 = va;
    va = newVarAlloc();
    final returnType = node.returnType;
    final parameters = <ParameterOperation>[];
    final name = getExpressionMethodName(node);
    method = MethodOperation(returnType, name, parameters, block);
    _methods[node] = method;
    final expressions = node.expressions.skip(1).toList();
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    final isProductive1 = isProductive;
    final result1 = va.newVar(block, returnType, null);
    void Function(BlockOperation) onSuccess;
    final results = <Expression, Variable>{};
    final isLastChildOptional = expressions.last.isOptional;
    void plunge(BlockOperation block, int index) {
      if (index > expressions.length - 1) {
        return;
      }

      final child = expressions[index];
      isProductive = child.isProductive;
      visitChild(child, block);
      results[child] = result;
      if (child.variable != null) {
        variables[child] = result;
      }

      if (index < expressions.length - 1) {
        if (child.isOptional) {
          plunge(block, index + 1);
        } else {
          addIfVar(block, m.success, (block) {
            plunge(block, index + 1);
          });
        }
      } else {
        if (hasAction) {
          addIfVar(block, m.success, (block) {
            final actionGenerator = ActionGenerator();
            actionGenerator.generate(block, node, result1, variables);
          });
        } else {
          if (variables.isEmpty) {
            onSuccess = (block) {
              final variable = results.values.first;
              addAssign(block, varOp(result1), varOp(variable));
            };
          } else if (variables.length == 1) {
            onSuccess = (block) {
              final expression = variables.keys.first;
              final variable = results[expression];
              addAssign(block, varOp(result1), varOp(variable));
            };
          } else {
            if (node.isProductive) {
              onSuccess = (block) {
                addIfVar(block, m.success, (block) {
                  final list =
                      listOp(null, variables.values.map(varOp).toList());
                  addAssign(block, varOp(result1), list);
                });
              };
            } else {
              //addAssign(b, varOp(result1), null);
            }
          }
        }

        if (onSuccess != null) {
          if (isLastChildOptional) {
            onSuccess(block);
          } else {
            addIfVar(block, m.success, onSuccess);
          }
        }
      }
    }

    plunge(block, 0);
    isProductive = isProductive1;
    result = result1;
    va = va1;
    block = block1;
  }
}
