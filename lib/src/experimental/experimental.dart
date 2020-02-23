part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionToOperationGenerator
    with OperationUtils {
  Map<Expression, MethodOperation> _methods;

  Map<Expression, ParameterOperation> _methodPostfixParameters;

  Map<Expression, ParameterOperation> _methodReturnParameters;

  Map<String, Variable> _methodVariables;

  final Grammar grammar;

  ExperimentalGenerator(this.grammar, ParserGeneratorOptions options)
      : super(options);

  @override
  ParameterOperation findPostfixParamater(Expression expression) {
    return _findMethodPostfixParameter(expression);
  }

  List<MethodOperation> generate() {
    isPostfix = true;
    _methods = {};
    _methodPostfixParameters = {};
    _methodReturnParameters = {};
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
    methods2.sort((a, b) => a.name.compareTo(b.name));
    return methods2;
  }

  @override
  String getRuleMethodName(ProductionRule rule) {
    final expression = rule.expression;
    return _getExpressionMethodName(expression);
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    if (node.index != 0) {
      super.visitAndPredicate(node);
    } else {
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        addCall(b, varOp(m.popState), []);
        resultVar = varAlloc.newVar(b, 'var', null);
      });
    }
  }

  @override
  void visitCapture(CaptureExpression node) {
    if (node.index != 0) {
      super.visitCapture(node);
    } else {
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        final start = varAlloc.newVar(b, 'var', null);
        final stopCapture = callOp(varOp(m.stopCapture), []);
        addAssign(b, varOp(start), stopCapture);
        addIfVar(b, m.success, (b) {
          final result = varAlloc.newVar(b, 'String', null);
          final substring = Variable('substring');
          final callSubstring = mbrCallOp(
              varOp(m.input), varOp(substring), [varOp(start), varOp(m.pos)]);
          addAssign(b, varOp(result), callSubstring);
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
    if (node.index != 0) {
      super.visitNotPredicate(node);
    } else {
      final varAlloc = getLocalVarAlloc();
      _generatePostfixMethod(node, varAlloc, (b) {
        addAssign(
            b, varOp(m.success), unaryOp(OperationKind.not, varOp(m.success)));
        addCall(b, varOp(m.popState), []);
        resultVar = varAlloc.newVar(b, 'var', null);
      });
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    if (node.index != 0) {
      super.visitOneOrMore(node);
    } else {
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
    if (node.index != 0) {
      super.visitOptional(node);
    } else {
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

    if (_hasChoiceMethod(node)) {
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
        addLoop(b, (b) {
          block = b;
          for (var i = 0; i < choices.length; i++) {
            final choice = choices[i];
            //var prefixCount = 0;
            for (var j = 0; j < choice.length; j++) {
              final expression = choice[j];
              if (expression is StartExpression) {
                final child = expression.expression;
                if (child is AndPredicateExpression ||
                    child is AndPredicateExpression) {
                  addCall(b, varOp(m.pushState), []);
                } else if (choice is CaptureExpression) {
                  addCall(b, varOp(m.startCapture), []);
                }

                //prefixCount++;
              } else if (expression is AnyCharacterExpression ||
                  expression is CharacterClassExpression ||
                  expression is LiteralExpression) {
                expression.accept(this);
              } else if (expression is SingleExpression) {
                expression.accept(this);
                final methodVar = _getMethodVariable(expression);
                final callExpr = callOp(varOp(methodVar), [varOp(resultVar)]);
                resultVar = varAlloc.newVar(block, 'var', callExpr);
              } else if (expression is SequenceExpression) {
                expression.accept(this);
                final methodVar = _getMethodVariable(expression);
                final callExpr = callOp(varOp(methodVar), [varOp(resultVar)]);
                resultVar = varAlloc.newVar(block, 'var', callExpr);
              } else if (expression is OrderedChoiceExpression) {
              } else {
                throw StateError(
                    'Invalid expresssion: ${expression.runtimeType}');
              }
            }

            if (i < choices.length - 1) {
              addIfVar(b, m.success, addBreak);
            } else {
              addBreak(b);
            }
          }
        });

        block = b;
        final returnParameter = _findMethodReturnParameter(node);
        addAssign(block, varOp(returnParameter.variable), varOp(resultVar));
      });
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final varAlloc = getLocalVarAlloc();
    _generatePostfixMethod(node, varAlloc, (b) {
      productive = varAlloc.newVar(b, 'var', constOp(true));
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
    if (node.index != 0) {
      super.visitZeroOrMore(node);
    } else {
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

  MethodOperation _findMethod(Expression expression) {
    final method = _methods[expression];
    if (method == null) {
      throw StateError('Expression method not found');
    }

    return method;
  }

  ParameterOperation _findMethodPostfixParameter(Expression expression) {
    final result = _methodPostfixParameters[expression];
    if (result == null) {
      throw StateError(
          'Unable to find method postfix parameter: ${expression}');
    }

    return result;
  }

  ParameterOperation _findMethodReturnParameter(Expression expression) {
    final result = _methodReturnParameters[expression];
    if (result == null) {
      throw StateError('Unable to find method return parameter: ${expression}');
    }

    return result;
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
    final parameters = <ParameterOperation>[];
    _generateMethod(expression, varAlloc, parameters, f);
  }

  void _generateMethod(Expression expression, VariableAllocator varAlloc,
      List<ParameterOperation> parameters, void Function(BlockOperation) f) {
    final variable = _getMethodVariable(expression);
    var method = _methods[expression];
    if (method != null) {
      return;
    }

    final returnType = expression.returnType;
    method = MethodOperation(returnType, variable.name, parameters);
    _methods[expression] = method;
    final prevResultVar = resultVar;
    final prevBlock = block;
    final prevVarAlloc = varAlloc;
    this.varAlloc = varAlloc;
    block = method.body;
    final returnVariable = varAlloc.alloc();
    final returnParameter = ParameterOperation(returnType, returnVariable);
    _methodReturnParameters[expression] = returnParameter;
    addOp(block, returnParameter);
    f(method.body);
    addReturn(block, varOp(returnVariable));
    this.varAlloc = prevVarAlloc;
    block = prevBlock;
    resultVar = prevResultVar;
  }

  void _generatePostfixMethod(Expression expression, VariableAllocator varAlloc,
      void Function(BlockOperation) f) {
    var parameterType = 'var';
    if (expression is SingleExpression) {
      final child = expression.expression;
      parameterType = child.returnType;
    } else if (expression is SequenceExpression) {
      final expressions = expression.expressions;
      parameterType = expressions[0].returnType;
    } else {
      StateError(
          'Unable to generate postfix nethod for expression: ${expression.runtimeType}');
    }

    final parameter = ParameterOperation(parameterType, varAlloc.alloc());
    _methodPostfixParameters[expression] = parameter;
    _generateMethod(expression, varAlloc, [parameter], f);
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
    if (node.index != 0) {
      final rule = node.expression.rule;
      final returnType = rule.returnType;
      final expression = rule.expression;
      final name = _getMethodVariable(expression);
      final callRule = callOp(varOp(name), []);
      final result = varAlloc.newVar(block, returnType, callRule);
      resultVar = result;
    } else {
      return;
    }
  }
}
