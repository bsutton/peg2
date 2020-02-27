part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionToOperationGenerator
    with OperationUtils {
  Map<Expression, MethodOperation> _methods;

  Map<String, Variable> _methodVariables;

  final Grammar grammar;

  ExperimentalGenerator(this.grammar, ParserGeneratorOptions options)
      : super(options);

  List<MethodOperation> generate() {
    isPostfixGenerator = true;
    _methods = {};
    _methodVariables = {};
    for (final rule in grammar.rules) {
      final expression = rule.expression;
      va = newVarAlloc();
      expression.accept(this);
    }

    // ignore: unused_local_variable
    final x = () {
      final nodes = <ExpressionNode>[];
      final expressionChainResolver = ExpressionChainResolver();
      for (final rule in grammar.rules) {
        final node = expressionChainResolver.resolve(rule.expression);
        nodes.add(node);
      }

      var ident = 0;
      void visit(ExpressionNode node) {
        final save = ident;
        final sb = StringBuffer();
        sb.write(''.padLeft(ident));
        sb.write(node.expression.runtimeType);
        sb.write(' (');
        sb.write(node.expression.rule);
        sb.write('): ');
        sb.write(node.expression);
        if (node.children.isEmpty) {
          sb.write(' END');
        }

        print(sb);
        ident += 2;
        for (final child in node.children) {
          visit(child);
        }

        ident = save;
      }

      for (final node in nodes) {
        print(node.expression.rule.name);
        print('-----------------');
        visit(node);
      }

      List<List<Expression>> flatten(ExpressionNode node) {
        final result = <List<Expression>>[];
        if (node.children.isEmpty) {
          result.add([node.expression]);
        } else {
          for (final child in node.children) {
            final branch = flatten(child);
            for (var element in branch) {
              element.add(node.expression);
              result.add(element);
            }
          }
        }

        return result;
      }

      for (final node in nodes) {
        print('-----------------');
        print(node.expression.rule.name);
        print('-----------------');
        final expressions = flatten(node);
        for (final element in expressions) {
          print('*******');
          print(element
              .map((e) => '${e.runtimeType} (${e.rule}): $e')
              .join('\n'));
        }
      }
    };

    final methods2 = _methods.values.toList();
    // TODO: Sort methods
    //methods2.sort((a, b) => a.name.compareTo(b.name));
    return methods2;
  }

  @override
  String getRuleMethodName(ProductionRule rule) {
    final expression = rule.expression;
    return _getExpressionMethodName(expression);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbolExpression(node);
  }

  void visitOrderedChoice_2(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    if (expressions.length > 1) {
      final list = SparseList<List<Expression>>();
      for (var i = 0; i < expressions.length; i++) {
        final child = expressions[i];
        for (final srcGroup in child.startCharacters.getGroups()) {
          final allSpace = list.getAllSpace(srcGroup);
          for (final dstGroup in allSpace) {
            var key = dstGroup.key;
            if (key == null) {
              key = [child];
            } else {
              key.add(child);
            }

            final newGroup = GroupedRangeList<List<Expression>>(
                dstGroup.start, dstGroup.end, key);
            list.addGroup(newGroup);
          }
        }
      }

      final states = <List<Expression>>[];
      int addState(List<Expression> expressions) {
        for (var i = 0; i < states.length; i++) {
          final state = states[i];
          if (expressions.length == state.length) {
            var found = true;
            for (var j = 0; j < expressions.length; j++) {
              if (expressions[j] != state[j]) {
                found = false;
                break;
              }
            }

            if (found) {
              return i;
            }
          }
        }

        states.add(expressions);
        return states.length - 1;
      }

      final failExpressions = <Expression>{};
      for (final expression in expressions) {
        final startCharacters = expression.startCharacters;
        if (startCharacters.groupCount == 1) {
          final group = startCharacters.groups.first;
          if (group.start == 0 && group.end == 0x10ffff) {
            failExpressions.add(expression);
          }
        }
      }

      final rangesAndStates = <int>[];
      for (var group in list.groups) {
        rangesAndStates.add(group.start);
        rangesAndStates.add(group.end);
        final state = addState(group.key);
        rangesAndStates.add(state);
      }
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    visitOrderedChoice_2(node);

    final expressions = node.expressions;
    for (final child in expressions) {
      child.accept(this);
    }

    if (node.parent != null) {
      final methodVar = _getMethodVariable(node);
      // TODO: callerId
      final parameters = [constOp(0), constOp(true)];
      final call = callOp(varOp(methodVar), parameters);
      resultVar = va.newVar(b, 'var', call);
    }

    _generateChoiceMethod(node, newVarAlloc(), (b) {
      final contexts = <Expression, Map<String, Variable>>{};
      Map<String, Variable> findContext(Expression expression) {
        final result = contexts[expression];
        if (result == null) {
          throw StateError('Unable to find context: ${expression.runtimeType}');
        }

        return result;
      }

      final c = va.newVar(b, 'var', varOp(m.c));
      final pos = va.newVar(b, 'var', varOp(m.pos));
      Expression prev;
      void visit(BlockOperation b, List<Expression> choice, int index) {
        if (index > choice.length - 1) {
          addIfVar(b, m.success, (b) {
            final returnParameter = findMethodParameter(node, paramReturn);
            addAssign(b, varOp(returnParameter.variable), varOp(resultVar));
            addBreak(b);
          });

          return;
        }

        final expression = choice[index];
        if (expression is StartExpression) {
          final child = expression.expression;
          if (child is AndPredicateExpression) {
            final c = va.newVar(b, 'var', varOp(m.c));
            final pos = va.newVar(b, 'var', varOp(m.pos));
            final predicate = va.newVar(b, 'var', varOp(m.predicate));
            final context = {
              'c': c,
              'pos': pos,
              'predicate': predicate,
            };

            contexts[child] = context;
            addAssign(b, varOp(m.predicate), constOp(true));
          } else if (child is NotPredicateExpression) {
            final c = va.newVar(b, 'var', varOp(m.c));
            final pos = va.newVar(b, 'var', varOp(m.pos));
            final predicate = va.newVar(b, 'var', varOp(m.predicate));
            final context = {
              'c': c,
              'pos': pos,
              'predicate': predicate,
            };

            contexts[child] = context;
            addAssign(b, varOp(m.predicate), constOp(true));
          } else if (child is CaptureExpression) {
            final start = va.newVar(b, 'var', varOp(m.pos));
            final prod = va.newVar(b, 'var', varOp(productive));
            final context = {
              'productive': prod,
              'start': start,
            };

            contexts[child] = context;
            addAssign(b, varOp(productive), constOp(false));
          }
        } else if (expression is AnyCharacterExpression ||
            expression is CharacterClassExpression ||
            expression is LiteralExpression) {
          acceptInBlock(b, va, expression);
        } else if (expression is SingleExpression) {
          if (expression is OptionalExpression) {
            addAssign(b, varOp(m.success), constOp(true));
          } else if (expression is AndPredicateExpression) {
            final context = findContext(expression);
            final c = context['c'];
            final pos = context['pos'];
            final predicate = context['predicate'];
            addAssign(b, varOp(m.c), varOp(c));
            addAssign(b, varOp(m.pos), varOp(pos));
            addAssign(b, varOp(m.predicate), varOp(predicate));
            resultVar = va.newVar(b, 'var', null);
          } else if (expression is NotPredicateExpression) {
            final context = findContext(expression);
            final c = context['c'];
            final pos = context['pos'];
            final predicate = context['predicate'];
            addAssign(b, varOp(m.c), varOp(c));
            addAssign(b, varOp(m.pos), varOp(pos));
            addAssign(b, varOp(m.predicate), varOp(predicate));
            resultVar = va.newVar(b, 'var', null);
            addAssign(b, varOp(m.success),
                unaryOp(OperationKind.not, varOp(m.success)));
          } else if (expression is CaptureExpression) {
            final context = findContext(expression);
            final start = context['start'];
            final prod = context['productive'];
            addAssign(b, varOp(productive), varOp(prod));
            resultVar = va.newVar(b, 'String', null);
            addIfVar(b, m.success, (b) {
              final substring = Variable('substring');
              final call = mbrCallOp(varOp(m.text), varOp(substring),
                  [varOp(start), varOp(m.pos)]);
              addAssign(b, varOp(resultVar), call);
            });
          } else if (expression is OneOrMoreExpression) {
            final child = expression.expression;
            final returnType = expression.returnType;
            final result = va.newVar(b, returnType, null);
            addIfVar(b, m.success, (b) {
              addIfElse(b, varOp(productive), (b) {
                addAssign(b, varOp(result), ListOperation(null, []));
                final add = Variable('add');
                addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
              });

              addLoop(b, (b) {
                acceptInBlock(b, va, child);
                addIfNotVar(b, m.success, (b) {
                  addAssign(b, varOp(m.success), constOp(true));
                  addBreak(b);
                });

                addIfElse(b, varOp(productive), (b) {
                  final add = Variable('add');
                  addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
                });
              });
            });
          } else if (expression is ZeroOrMoreExpression) {
            final child = expression.expression;
            final returnType = expression.returnType;
            final result = va.newVar(b, returnType, null);
            addIfVar(b, m.success, (b) {
              addIfElse(b, varOp(productive), (b) {
                addAssign(b, varOp(result), ListOperation(null, []));
              });

              addLoop(b, (b) {
                acceptInBlock(b, va, child);
                addIfNotVar(b, m.success, addBreak);
                addIfElse(b, varOp(productive), (b) {
                  final add = Variable('add');
                  addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
                });
              });
            });

            addAssign(b, varOp(m.success), constOp(true));
            resultVar = result;
          } else {
            throw StateError('Invalid expresssion: ${expression.runtimeType}');
          }
        } else if (expression is SequenceExpression) {
          final returnType = expression.returnType;
          final result = va.newVar(b, returnType, null);
          addIfVar(b, m.success, (b) {
            acceptInBlock(b, va, expression);
            final methodVar = _getMethodVariable(expression);
            final parameters = [varOp(resultVar), constOp(true)];
            final call = callOp(varOp(methodVar), parameters);
            addAssign(b, varOp(result), call);
            resultVar = result;
          });
        } else if (expression is OrderedChoiceExpression) {
          final rule = expression.rule;
          final isTerminal = expression.parent == null &&
              rule.kind == ProductionRuleKind.terminal;
          if (prev is OrderedChoiceExpression) {
            if (isTerminal) {
              addIfNotVar(b, m.success, (b) {
                if (isTerminal) {
                  final params = [varOp(pos), constOp(rule.name)];
                  final fail = callOp(varOp(m.fail), params);
                  addOp(b, fail);
                }
              });
            }
          } else {
            addIfNotVar(b, m.success, (b) {
              addAssign(b, varOp(m.c), varOp(c));
              addAssign(b, varOp(m.pos), varOp(pos));
              final rule = expression.rule;
              if (isTerminal) {
                final params = [varOp(pos), constOp(rule.name)];
                final fail = callOp(varOp(m.fail), params);
                addOp(b, fail);
              }
            });
          }
        } else {
          throw StateError('Invalid expresssion: ${expression.runtimeType}');
        }

        prev = expression;
        visit(b, choice, index + 1);
      }

      final expressionChainResolver = ExpressionChainResolver();
      final root = expressionChainResolver.resolve(node);
      final choices = _flattenNode(root);
      addLoop(b, (b) {
        bool reduce(Expression expression) {
          if (expression is SequenceExpression) {
            if (expression.expressions.length == 1) {
              if (expression.actionIndex == null) {
                // This is just a wrapper. Remove it.
                return false;
              }
            }
          }

          return true;
        }

        for (var i = 0; i < choices.length; i++) {
          final choice = choices[i].where(reduce).toList();
          final terminals = choice.reversed.where((e) {
            if (e is OrderedChoiceExpression) {
              if (e.parent == null) {
                if (e.rule.kind == ProductionRuleKind.terminal) {
                  return true;
                }
              }
            }

            return false;
          });

          if (terminals.length == 1) {
            addAssign(b, varOp(m.fposEnd), constOp(-1));
          } else if (terminals.length > 1) {
            throw StateError('To many terminals');
          }

          prev = null;
          visit(b, choice, 0);
          if (i >= choices.length - 1) {
            addBreak(b);
          }

          /*
          if (i < choices.length - 1) {
            addIfVar(b, m.success, (b) {
              final returnParameter = findMethodParameter(node, paramReturn);
              addAssign(b, varOp(returnParameter.variable), varOp(resultVar));
              addBreak(b);
            });
          } else {
            addIfVar(b, m.success, (b) {
              final returnParameter = findMethodParameter(node, paramReturn);
              addAssign(b, varOp(returnParameter.variable), varOp(resultVar));
            });

            addBreak(b);
          }
          */
        }
      });
    });
  }

  @override
  void visitSequence(SequenceExpression node) {
    final varAlloc = newVarAlloc();
    _generatePostfixMethod(node, varAlloc, (b) {
      productive = findMethodParameter(node, paramProductive).variable;
      super.visitSequence(node);
    });
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbolExpression(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbolExpression(node);
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

  void _generateChoiceMethod(OrderedChoiceExpression expression,
      VariableAllocator varAlloc, void Function(BlockOperation) f) {
    final callerId = ParameterOperation('int', varAlloc.alloc());
    final productive = ParameterOperation('bool', varAlloc.alloc());
    final parameters = {
      paramCallerId: callerId,
      paramProductive: productive,
    };

    _generateMethod(expression, varAlloc, parameters, f);
  }

  void _generateMethod(
      Expression expression,
      VariableAllocator va,
      Map<String, ParameterOperation> parameters,
      void Function(BlockOperation) f) {
    final variable = _getMethodVariable(expression);
    var method = _methods[expression];
    if (method != null) {
      return;
    }

    final returnType = expression.returnType;
    final params = <ParameterOperation>[];
    for (final name in parameters.keys) {
      final parameter = parameters[name];
      params.add(parameter);
      addMethodParameter(expression, name, parameter);
    }

    method = MethodOperation(returnType, variable.name, params);
    _methods[expression] = method;
    final rv = resultVar;
    final b = method.body;
    final returnVariable = va.alloc();
    final returnParam = ParameterOperation(returnType, returnVariable);
    addMethodParameter(expression, paramReturn, returnParam);
    addOp(b, returnParam);
    final pva = this.va;
    this.va = va;
    runInBlock(b, () => f(b));
    this.va = pva;
    addReturn(b, varOp(returnVariable));
    resultVar = rv;
  }

  void _generatePostfixMethod(Expression expression, VariableAllocator va,
      void Function(BlockOperation) f) {
    var postfixType = 'var';
    if (expression is SingleExpression) {
      final child = expression.expression;
      postfixType = child.returnType;
    } else if (expression is SequenceExpression) {
      final expressions = expression.expressions;
      postfixType = expressions[0].returnType;
    } else {
      StateError(
          'Unable to generate postfix nethod for expression: ${expression.runtimeType}');
    }

    final postfix = ParameterOperation(postfixType, va.alloc());
    final productive = ParameterOperation('bool', va.alloc());
    final parameters = {
      paramPostfix: postfix,
      paramProductive: productive,
    };

    _generateMethod(expression, va, parameters, f);
  }

  String _getExpressionMethodName(Expression expression) {
    final id = expression.id;
    final name = '_e$id';
    return name;
  }

  Variable _getMethodVariable(Expression expression) {
    final name = _getExpressionMethodName(expression);
    var variable = _methodVariables[name];
    if (variable == null) {
      variable = Variable(name);
      _methodVariables[name] = variable;
    }

    return variable;
  }

  void _visitSymbolExpression(SymbolExpression node) {
    final rule = node.expression.rule;
    var returnType = rule.returnType;
    final expression = rule.expression;
    returnType ??= rule.expression.returnType;
    final name = _getMethodVariable(expression);
    final parameters = [constOp(0), constOp(true)];
    final call = callOp(varOp(name), parameters);
    final result = va.newVar(b, returnType, call);
    resultVar = result;
  }
}
