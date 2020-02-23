part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionToOperationGenerator
    with OperationUtils {
  Map<Expression, MethodOperation> _methods;

  Map<String, Variable> _methodVariables;

  bool _isPostfixVisit = false;

  final Grammar grammar;

  ExperimentalGenerator(this.grammar, ParserGeneratorOptions options)
      : super(options);

  List<MethodOperation> generate() {
    isPostfixGenerator = true;
    _methods = {};
    _methodVariables = {};
    for (final rule in grammar.rules) {
      final expression = rule.expression;
      expression.accept(this);
    }

    void diag() {
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
    }

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
  void visitAndPredicate(AndPredicateExpression node) {
    if (!_isPostfixVisit) {
      super.visitAndPredicate(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        addCall(b, varOp(m.popState), []);
      });
    }
  }

  @override
  void visitCapture(CaptureExpression node) {
    if (!_isPostfixVisit) {
      super.visitCapture(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        final stopCapture = callOp(varOp(m.stopCapture), []);
        final start = varAlloc.newVar(b, 'var', stopCapture);
        addIfVar(b, m.success, (b) {
          final substring = Variable('substring');
          final callSubstring = mbrCallOp(
              varOp(m.input), varOp(substring), [varOp(start), varOp(m.pos)]);
          final ret = findMethodParameter(node, paramReturn);
          addAssign(b, varOp(ret.variable), callSubstring);
        });
      });
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbolExpression(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    if (!_isPostfixVisit) {
      super.visitNotPredicate(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        addCall(b, varOp(m.popState), []);
        addAssign(
            b, varOp(m.success), unaryOp(OperationKind.not, varOp(m.success)));
      });
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    if (!_isPostfixVisit) {
      super.visitOneOrMore(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        final returnType = node.returnType;
        final result = varAlloc.newVar(b, returnType, null);
        addIfVar(b, m.success, (b) {
          addIfElse(b, varOp(productive), (b) {
            addAssign(b, varOp(result), ListOperation(null, []));
            final add = Variable('add');
            addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
          });

          addLoop(b, (b) {
            block = b;
            node.expression.accept(this);
            addIfNotVar(b, m.success, (b) {
              addAssign(block, varOp(m.success), constOp(true));
              addBreak(b);
            });

            addIfElse(b, varOp(productive), (b) {
              final add = Variable('add');
              addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
            });
          });
        });
      });
    }
  }

  @override
  void visitOptional(OptionalExpression node) {
    if (!_isPostfixVisit) {
      super.visitOptional(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        addAssign(block, varOp(m.success), constOp(true));
      });
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    for (final child in expressions) {
      child.accept(this);
    }

    if (node.parent != null) {
      final methodVar = _getMethodVariable(node);
      // TODO: callerId
      final parameters = [constOp(0), constOp(true)];
      final callExpr = callOp(varOp(methodVar), parameters);
      resultVar = this.varAlloc.newVar(block, 'var', callExpr);
    }

    final varAlloc = getLocalVarAlloc();
    _generateChoiceMethod(node, varAlloc, (b) {
      /*
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
        */

      final expressionChainResolver = ExpressionChainResolver();
      final root = expressionChainResolver.resolve(node);
      final choices = _flattenNode(root);
      final b = block;

      // TODO
      addAssign(b, varOp(m.failed), constOp(-1));

      addLoop(b, (b) {
        block = b;
        for (var i = 0; i < choices.length; i++) {
          final choice =
              choices[i].where((e) => e is! OrderedChoiceExpression).toList();
          //var prefixCount = 0;
          for (var j = 0; j < choice.length; j++) {
            final expression = choice[j];
            if (expression is StartExpression) {
              final child = expression.expression;
              if (child is AndPredicateExpression ||
                  child is NotPredicateExpression) {
                addCall(b, varOp(m.pushState), []);
              } else if (child is CaptureExpression) {
                addCall(b, varOp(m.startCapture), []);
              }

              //prefixCount++;
            } else if (expression is AnyCharacterExpression ||
                expression is CharacterClassExpression ||
                expression is LiteralExpression) {
              expression.accept(this);
            } else if (expression is SingleExpression) {
              if (expression is OptionalExpression) {
                addAssign(b, varOp(m.success), constOp(true));
              } else if (expression is AndPredicateExpression) {
                final popState = callOp(varOp(m.popState), []);
                resultVar = varAlloc.newVar(b, 'var', popState);
              } else if (expression is NotPredicateExpression) {
                final popState = callOp(varOp(m.popState), []);
                resultVar = varAlloc.newVar(b, 'var', popState);
                addAssign(b, varOp(m.success),
                    unaryOp(OperationKind.not, varOp(m.success)));
              } else {
                _isPostfixVisit = true;
                expression.accept(this);
                final methodVar = _getMethodVariable(expression);
                final parameters = [varOp(resultVar), constOp(true)];
                final callExpr = callOp(varOp(methodVar), parameters);
                resultVar = varAlloc.newVar(block, 'var', callExpr);
              }
            } else if (expression is SequenceExpression) {
              if (expression.expressions.length > 1 ||
                  expression.actionIndex != null) {
                expression.accept(this);
                final methodVar = _getMethodVariable(expression);
                final parameters = [varOp(resultVar), constOp(true)];
                final callExpr = callOp(varOp(methodVar), parameters);
                resultVar = varAlloc.newVar(block, 'var', callExpr);
              } else {
                // Skip
              }
            } else {
              throw StateError(
                  'Invalid expresssion: ${expression.runtimeType}');
            }
          }

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
        }
      });

      block = b;
    });
  }

  @override
  void visitSequence(SequenceExpression node) {
    final varAlloc = getLocalVarAlloc();
    _generatePostfixMethod(node, varAlloc, (b) {
      if (node.id == 42) {
        var x = 0;
      }

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

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    if (!_isPostfixVisit) {
      super.visitZeroOrMore(node);
    } else {
      _isPostfixVisit = false;
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        final returnType = node.returnType;
        final result = varAlloc.newVar(b, returnType, null);
        addIfVar(b, m.success, (b) {
          addIfElse(b, varOp(productive), (b) {
            addAssign(b, varOp(result), ListOperation(null, []));
          });

          addLoop(b, (b) {
            block = b;
            node.expression.accept(this);
            addIfNotVar(b, m.success, addBreak);
            addIfElse(b, varOp(productive), (b) {
              final add = Variable('add');
              addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
            });
          });
        });

        addAssign(b, varOp(m.success), constOp(true));
        resultVar = result;
      });
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
      VariableAllocator varAlloc,
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
    final prevResultVar = resultVar;
    final prevBlock = block;
    final prevVarAlloc = this.varAlloc;
    this.varAlloc = varAlloc;
    block = method.body;
    final returnVariable = varAlloc.alloc();
    final returnParam = ParameterOperation(returnType, returnVariable);
    addMethodParameter(expression, paramReturn, returnParam);
    addOp(block, returnParam);
    f(method.body);
    addReturn(block, varOp(returnVariable));
    this.varAlloc = prevVarAlloc;
    block = prevBlock;
    resultVar = prevResultVar;
  }

  void _generatePostfixMethod(Expression expression, VariableAllocator varAlloc,
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

    final postfix = ParameterOperation(postfixType, varAlloc.alloc());
    final productive = ParameterOperation('bool', varAlloc.alloc());
    final parameters = {
      paramPostfix: postfix,
      paramProductive: productive,
    };

    _generateMethod(expression, varAlloc, parameters, f);
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

  bool _hasChoiceMethod(OrderedChoiceExpression expression) {
    var result = false;
    final parent = expression.parent;
    if (parent == null || expression.expressions.length > 1) {
      result = true;
    }

    return result;
  }

  void _visitSymbolExpression(SymbolExpression node) {
    final rule = node.expression.rule;
    var returnType = rule.returnType;
    final expression = rule.expression;
    returnType ??= rule.expression.returnType;
    final name = _getMethodVariable(expression);
    final parameters = [constOp(0), constOp(true)];
    final callRule = callOp(varOp(name), parameters);
    final result = varAlloc.newVar(block, returnType, callRule);
    resultVar = result;
  }
}
