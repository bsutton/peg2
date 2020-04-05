part of '../../general_parser_generator.dart';

class GeneralExpressionOperationGenerator extends ExpressionOperationGenerator {
  GeneralExpressionOperationGenerator(ParserGeneratorOptions options,
      BlockOperation block, VariableAllocator va)
      : super(options, block, va);

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final rule = node.rule;
    var returnType = node.returnType;
    if (node.parent == null) {
      returnType = rule.returnType;
      returnType ??= node.returnType;
    }

    final id = node.id;
    final isOnTop = node.parent == null;
    final willInline = !isOnTop || needToInline(rule, options);
    final willMemoize = isOnTop && needToMemoize(rule, options);
    final result1 = va.newVar(block, returnType, null);
    final pos = va.newVar(block, 'final', varOp(m.pos));
    void callMemoize() {
      final test = varOp(memoize);
      addIf(block, test, (block) {
        final memoize =
            callOp(varOp(m.memoize), [constOp(id), varOp(pos), varOp(result)]);
        addOp(block, memoize);
      });
    }

    if (willMemoize) {
      final memoized = callOp(varOp(m.memoized), [constOp(id)]);
      final testMemoized = landOp(varOp(memoize), memoized);
      if (isOnTop) {
        addIf(block, testMemoized, (block) {
          final convert = convertOp(varOp(m.mresult), returnType);
          addReturn(block, convert);
        });

        runInBlock(block, () => _generateOrderedChoice(node, result1));
        runInBlock(block, callMemoize);
      } else {
        addIf(block, testMemoized, (block) {
          final convert = convertOp(varOp(m.mresult), returnType);
          addAssign(block, varOp(result1), convert);
        }, (block) {
          runInBlock(block, () => _generateOrderedChoice(node, result1));
          runInBlock(block, callMemoize);
        });
      }
    } else {
      runInBlock(block, () => _generateOrderedChoice(node, result1));
    }

    if (isOnTop && !willInline) {
      addReturn(block, varOp(result1));
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    final returnType = node.returnType;
    final isProductive1 = isProductive;
    final result1 = va.newVar(block, returnType, null);
    final c = va.newVar(block, 'final', varOp(m.c));
    final pos = va.newVar(block, 'final', varOp(m.pos));
    void Function(BlockOperation) onSuccess;
    final results = <Expression, Variable>{};
    final isLastChildOptional = expressions.last.isOptional;
    final optionalCount = expressions.where((e) => e.isOptional).length;
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
          onSuccess = (block) {
            final actionGenerator = ActionGenerator();
            var actionBlock = block;
            // Need sorround in separate block?
            if (block.operations.isNotEmpty) {
              actionBlock = BlockOperation();
              addOp(block, actionBlock);
            }

            actionGenerator.generate(actionBlock, node, result1, variables);
          };
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

      if (index == 1) {
        if (optionalCount != expressions.length - 1) {
          addIfNotVar(block, m.success, (block) {
            addAssign(block, varOp(m.c), varOp(c));
            addAssign(block, varOp(m.pos), varOp(pos));
          });
        }
      }
    }

    plunge(block, 0);
    isProductive = isProductive1;
    result = result1;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbol(node);
  }

  void _generateOrderedChoice(OrderedChoiceExpression node, Variable result1) {
    final expressions = node.expressions;
    final rule = node.rule;
    final isTopTerminal =
        node.parent == null && rule.kind == ProductionRuleKind.terminal;
    final isTerminal = rule.kind == ProductionRuleKind.terminal;
    final isNonterminal = rule.kind == ProductionRuleKind.nonterminal;
    final c = va.newVar(block, 'final', varOp(m.c));
    final pos = va.newVar(block, 'final', varOp(m.pos));
    Variable failure;
    if (isTerminal) {
      failure = va.newVar(block, 'var', varOp(m.pos));
    }

    //final ifNotSuccess = BlockOperation();
    if (expressions.length > 1) {
      addLoop(block, (block) {
        for (var i = 0; i < expressions.length; i++) {
          final child = expressions[i];
          visitChild(child, block);
          if (isTerminal) {
            final test = ltOp(varOp(failure), varOp(m.failure));
            addIf(block, test, (block) {
              addAssign(block, varOp(failure), varOp(m.failure));
            });
          }

          addIfVar(block, m.success, (block) {
            addAssign(block, varOp(result1), varOp(result));
            addBreak(block);
          });

          if (child.expressions.length > 1) {
            addAssign(block, varOp(m.c), varOp(c));
            addAssign(block, varOp(m.pos), varOp(pos));
          }

          if (i < expressions.length - 1) {
            //
          } else {
            if (isTerminal) {
              addAssign(block, varOp(m.failure), varOp(failure));
            }

            addBreak(block);
          }
        }
      });
    } else {
      final child = expressions[0];
      visitChild(child, block);
      addAssign(block, varOp(result1), varOp(result));
    }

    final startTerminals = node.startTerminals;
    void fail(BlockOperation block) {
      final terminals = startTerminals.map((e) => e.name);
      final elements = terminals.map(constOp).toList();
      final list = listOp('const', elements);
      addCall(block, varOp(m.fail), [list]);
    }

    if (isTopTerminal) {
      final testSuccess = notOp(varOp(m.success));
      final testError = lteOp(varOp(m.error), varOp(m.failure));
      final test = landOp(testSuccess, testError);
      addIf(block, test, fail);
    } else if (isNonterminal) {
      final testSuccess = notOp(varOp(m.success));
      final testError = eqOp(varOp(m.error), varOp(pos));
      final test = landOp(testSuccess, testError);
      addIf(block, test, fail);
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

    result = result1;
  }

  void _visitSymbol(SymbolExpression node) {
    final rule = node.expression.rule;
    final willInline = needToInline(rule, options);
    final startCharacters = node.startCharacters;
    var predict = false;
    if (options.predict) {
      if (rule.kind == ProductionRuleKind.subterminal ||
          rule.kind == ProductionRuleKind.terminal) {
        if (startCharacters.groups.length < 10) {
          if (!node.isOptional) {
            predict = true;
          } else {
            if (!node.isProductive) {
              predict = true;
            }
          }
        }
      }
    }

    Variable generate(BlockOperation block) {
      Variable result1;
      if (willInline) {
        final child = rule.expression;
        visitChild(child, block);
        result1 = result;
      } else {
        final productionRuleNameGenerator = ProductionRuleNameGenerator();
        final ruleName = productionRuleNameGenerator.generate(rule);
        final name = Variable(ruleName, true);
        Operation productive1;
        if (isProductive) {
          productive1 = isProductive ? varOp(productive) : constOp(false);
        } else {
          productive1 = constOp(false);
        }

        final call = callOp(varOp(name), [constOp(node.memoize), productive1]);
        result1 = va.newVar(block, 'final', call);
      }

      return result1;
    }

    Variable result1;
    if (predict) {
      void onSuccess(BlockOperation block) {
        result = generate(block);
        addAssign(block, varOp(result1), varOp(result));
      }

      void onFail(BlockOperation block) {
        if (rule.expression.isSuccessful) {
          addAssign(block, varOp(m.success), constOp(true));
        } else {
          final terminals = node.startTerminals.map((e) => e.name);
          final elements = terminals.map(constOp).toList();
          final list = listOp('const', elements);
          final params = [varOp(m.pos), list];
          final fail = callOp(varOp(m.failAt), params);
          addOp(block, fail);

          //addAssign(block, varOp(m.success), constOp(false));
          //addAssign(block, varOp(m.failure), varOp(m.pos));
          //final test = lteOp(varOp(m.error), varOp(m.failure));
          //addIf(block, test, (block) {
          //  final params = [listOp('const', [])];
          //  final fail = callOp(varOp(m.fail), params);
          //  addOp(block, fail);
          //});

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
      }

      final c = va.newVar(block, 'final', varOp(m.c));
      final returnType = node.returnType;
      result1 = va.newVar(block, returnType, null);
      final rangesOperationGenerator = RangesOperationGenerator();
      rangesOperationGenerator.generateConditional(
          block, c, startCharacters, onSuccess, onFail);
    } else {
      result1 = generate(block);
    }

    result = result1;
  }
}
