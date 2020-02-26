part of '../../operation_generators.dart';

abstract class ExpressionToOperationGenerator extends ExpressionVisitor
    with OperationUtils {
  BlockOperation b;

  final ParserClassMembers m = ParserClassMembers();

  bool isPostfixGenerator = false;

  Map<Expression, Map<String, ParameterOperation>> methodParameters = {};

  bool notProductive;

  final ParserGeneratorOptions options;

  final String paramCallerId = 'callerID';

  final String paramPostfix = 'postfix';

  final String paramProductive = 'productive';

  final String paramReturn = 'return';

  Variable productive;

  Variable resultVar;

  VariableAllocator va;

  ExpressionToOperationGenerator(this.options);

  void acceptInBlock(BlockOperation b, VariableAllocator va, Expression e) {
    runInBlock(b, () => e.accept(this));
  }

  ParameterOperation addMethodParameter(
      Expression expression, String name, ParameterOperation parameter) {
    var parameters = methodParameters[expression];
    if (parameters == null) {
      parameters = {};
      methodParameters[expression] = parameters;
    }

    if (parameters.containsKey(name)) {
      throw StateError('Method parameter already exists: $name');
    }

    parameters[name] = parameter;
    return parameter;
  }

  ParameterOperation findMethodParameter(Expression expression, String name) {
    final parameters = methodParameters[expression];
    if (parameters == null) {
      throw StateError('Unable to find method parameters: ${expression}');
    }

    if (!parameters.containsKey(name)) {
      throw StateError('Unable to find method parameter: $name');
    }

    return parameters[name];
  }

  VariableAllocator newVarAlloc() {
    var lastVariableId = 0;
    final result = VariableAllocator(() {
      final name = '\$${lastVariableId++}';
      return name;
    });

    return result;
  }

  String getRuleMethodName(ProductionRule rule);

  void runInBlock(BlockOperation b, void Function() f) {
    final pb = this.b;
    this.b = b;
    f();
    this.b = pb;
  }

  Operation testRanges(List<int> ranges) {
    Operation op(int start, int end) {
      if (start == end) {
        return equalOp(varOp(m.c), constOp(start));
      } else {
        final left = gteOp(varOp(m.c), constOp(start));
        final right = lteOp(varOp(m.c), constOp(end));
        return landOp(left, right);
      }
    }

    if (ranges[0] == 0 && ranges[1] == 0x10ffff) {
      // Allows match EOF
      ranges[1] = 0x10ffff + 1;
    }

    var result = op(ranges[0], ranges[1]);
    for (var i = 2; i < ranges.length; i += 2) {
      final right = op(ranges[i], ranges[i + 1]);
      result = lorOp(result, right);
    }

    return result;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final child = node.expression;
    final state = saveVars(b, va, [
      m.c,
      m.pos,
      m.predicate,
      productive,
    ]);

    addAssign(b, varOp(m.predicate), constOp(true));
    addAssign(b, varOp(productive), constOp(false));
    child.accept(this);
    final result = va.newVar(b, 'var', null);
    restoreVars(b, state);
    resultVar = result;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final result = va.newVar(b, 'int', null);
    final test = ltOp(varOp(m.c), varOp(m.eof));
    addAssign(b, varOp(m.success), test);
    addIfElse(b, varOp(m.success), (b) {
      addAssign(b, varOp(result), varOp(m.c));
      final testC = lteOp(varOp(m.c), constOp(0xffff));
      final ternary = TernaryOperation(testC, constOp(1), constOp(2));
      final assignPos = addAssignOp(varOp(m.pos), ternary);
      final listAcc = ListAccessOperation(varOp(m.input), assignPos);
      addAssign(b, varOp(m.c), listAcc);
    }, (b) {
      final test = binOp(OperationKind.lt, varOp(m.fposEnd), varOp(m.pos));
      addIf(b, test, (b) {
        addAssign(b, varOp(m.fposEnd), varOp(m.pos));
      });
    });

    resultVar = result;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final result = va.newVar(b, 'String', null);
    final start = va.newVar(b, 'var', varOp(m.pos));
    final saved = saveVars(b, va, [productive]);
    addAssign(b, varOp(productive), constOp(false));
    node.expression.accept(this);
    addIfVar(b, m.success, (b) {
      final substring = Variable('substring');
      final callSubstring = mbrCallOp(
          varOp(m.text), varOp(substring), [varOp(start), varOp(m.pos)]);
      addAssign(b, varOp(result), callSubstring);
    });

    restoreVars(b, saved);
    resultVar = result;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final ranges = <int>[];
    for (final range in node.ranges) {
      ranges.addAll(range);
    }

    Variable result;
    if (ranges.length <= 20) {
      result = va.newVar(b, 'int', null);
      final test = testRanges(ranges);
      addIfElse(b, test, (b) {
        addAssign(b, varOp(m.success), constOp(true));
        addAssign(b, varOp(result), varOp(m.c));
        final testC = lteOp(varOp(m.c), constOp(0xffff));
        final ternary = TernaryOperation(testC, constOp(1), constOp(2));
        final assignPos = addAssignOp(varOp(m.pos), ternary);
        final listAcc = ListAccessOperation(varOp(m.input), assignPos);
        addAssign(b, varOp(m.c), listAcc);
      }, (b) {
        addAssign(b, varOp(m.success), constOp(false));
        final test = ltOp(varOp(m.fposEnd), varOp(m.pos));
        addIf(b, test, (b) {
          addAssign(b, varOp(m.fposEnd), varOp(m.pos));
        });
      });
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(ConstantOperation(ranges[i]));
        elements.add(ConstantOperation(ranges[i + 1]));
      }

      final listOp = ListOperation(null, elements);
      final list = va.newVar(b, 'const', listOp);
      final matchRanges = callOp(varOp(m.matchRanges), [varOp(list)]);
      result = va.newVar(b, 'var', matchRanges);
    }

    resultVar = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    final runes = text.runes;
    Variable result;
    if (runes.length == 1) {
      final rune = runes.first;
      result = va.newVar(b, 'String', null);
      final test = equalOp(varOp(m.c), constOp(rune));
      addAssign(b, varOp(m.success), test);
      addIfElse(b, varOp(m.success), (b) {
        addAssign(b, varOp(result), constOp(text));
        Operation posAssign;
        if (rune <= 0xffff) {
          posAssign = unaryOp(OperationKind.preInc, varOp(m.pos));
        } else {
          posAssign = addAssignOp(varOp(m.pos), constOp(2));
        }

        final listAcc = ListAccessOperation(varOp(m.input), posAssign);
        addAssign(b, varOp(m.c), listAcc);
      }, (b) {
        final test = ltOp(varOp(m.fposEnd), varOp(m.pos));
        addIf(b, test, (b) {
          addAssign(b, varOp(m.fposEnd), varOp(m.pos));
        });
      });
    } else if (runes.length > 1) {
      final rune = runes.first;
      result = va.newVar(b, 'String', null);
      final test = equalOp(varOp(m.c), constOp(rune));
      addIfElse(b, test, (b) {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        addAssign(b, varOp(result), matchString);
      }, (b) {
        addAssign(b, varOp(m.success), constOp(false));
        final test = ltOp(varOp(m.fposEnd), varOp(m.pos));
        addIf(b, test, (b) {
          addAssign(b, varOp(m.fposEnd), varOp(m.pos));
        });
      });
    } else {
      result = va.newVar(b, 'var', constOp(''));
      addAssign(b, varOp(m.success), constOp(true));
    }

    resultVar = result;
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    final state = saveVars(b, va, [
      m.c,
      m.pos,
      m.predicate,
      productive,
    ]);

    addAssign(b, varOp(m.predicate), constOp(true));
    addAssign(b, varOp(productive), constOp(false));
    child.accept(this);
    resultVar = va.newVar(b, 'var', null);
    addAssign(
        b, varOp(m.success), unaryOp(OperationKind.not, varOp(m.success)));
    restoreVars(b, state);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), ListOperation(null, []));
      });
    } else {
      // Do nothing
    }

    final passed = va.newVar(b, 'var', constOp(false));
    addLoop(b, (b) {
      acceptInBlock(b, va, child);
      addIfNotVar(b, m.success, (b) {
        addAssign(b, varOp(m.success), varOp(passed));
        addIfNotVar(b, m.success, (b) {
          addAssign(b, varOp(result), constOp(null));
        });

        addBreak(b);
      });

      if (node.isProductive) {
        addIfElse(b, varOp(productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
        });
      } else {
        // Do nothing
      }

      addAssign(b, varOp(passed), constOp(true));
    });

    resultVar = result;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    addAssign(b, varOp(m.success), constOp(true));
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    Variable result;
    if (isPostfixGenerator) {
      final returnParam = findMethodParameter(node, paramReturn);
      result = returnParam.variable;
    } else {
      result = va.newVar(b, node.returnType, null);
    }

    void Function(BlockOperation) onSuccess;
    void Function(BlockOperation) onFailure;
    var hasSavedState = !node.isOptional;
    if (expressions.length == 1) {
      hasSavedState = false;
    }

    if (isPostfixGenerator) {
      hasSavedState = false;
    }

    Map<Variable, Variable> savedState;
    if (hasSavedState) {
      savedState = saveVars(b, va, [m.c, m.pos]);
    }

    final results = <Expression, Variable>{};
    void plunge(BlockOperation b, List<Expression> seq, int index) {
      if (index > seq.length - 1) {
        return;
      }

      final child = seq[index];
      notProductive = !child.isProductive;
      if (index == 0) {
        if (isPostfixGenerator) {
          final parameter = findMethodParameter(node, paramPostfix);
          resultVar = parameter.variable;
        } else {
          acceptInBlock(b, va, child);
        }
      } else {
        acceptInBlock(b, va, child);
      }

      results[child] = resultVar;
      if (child.variable != null) {
        variables[child] = resultVar;
      }

      if (index < seq.length - 1) {
        if (child.isOptional) {
          plunge(b, seq, index + 1);
        } else {
          addIfVar(b, m.success, (b) {
            runInBlock(b, () => plunge(b, seq, index + 1));
          });
        }
      } else {
        if (hasAction) {
          onSuccess = (b) {
            _buildAction(b, node, result, variables);
          };
        } else {
          if (variables.isEmpty) {
            onSuccess = (b) {
              final variable = results.values.first;
              addAssign(b, varOp(result), varOp(variable));
            };
          } else if (variables.length == 1) {
            onSuccess = (b) {
              final expression = variables.keys.first;
              final variable = results[expression];
              addAssign(b, varOp(result), varOp(variable));
            };
          } else {
            onSuccess = (b) {
              if (node.isProductive) {
                final list =
                    ListOperation(null, variables.values.map(varOp).toList());
                addAssign(b, varOp(result), list);
              } else {
                // TODO:
                addAssign(b, varOp(result), null);
              }
            };
          }
        }

        addIfVar(b, m.success, onSuccess);
      }
    }

    runInBlock(b, () => plunge(b, expressions, 0));
    if (hasSavedState) {
      onFailure = (b) {
        restoreVars(b, savedState);
      };
    }

    if (onFailure != null) {
      addIfNotVar(b, m.success, onFailure);
    }

    resultVar = result;
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    final returnType = node.returnType;
    final result = va.newVar(b, returnType, null);
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), ListOperation(null, []));
      });
    } else {
      // Do nothing
    }

    addLoop(b, (b) {
      acceptInBlock(b, va, child);
      addIfNotVar(b, m.success, addBreak);
      if (node.isProductive) {
        addIfElse(b, varOp(productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(resultVar)]);
        });
      } else {
        // Do nothing
      }
    });

    addAssign(b, varOp(m.success), constOp(true));
    resultVar = result;
  }

  void _buildAction(BlockOperation b, SequenceExpression node, Variable result,
      Map<Expression, Variable> variables) {
    for (final expression in variables.keys) {
      final variable = Variable(expression.variable);
      final parameter =
          ParameterOperation('var', variable, varOp(variables[expression]));
      b.operations.add(parameter);
    }

    final $$ = Variable('\$\$');
    final returnType = node.returnType;
    final parameter = ParameterOperation(returnType, $$);
    b.operations.add(parameter);
    final code = <String>[];
    final lineSplitter = LineSplitter();
    var lines = lineSplitter.convert(node.actionSource);
    if (lines.length == 1) {
      final line = lines[0];
      code.add(line.trim());
    } else {
      final temp = <String>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isNotEmpty) {
          temp.add(line);
        }
      }

      lines = temp;
      int indent;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        var j = 0;
        for (; j < line.length; j++) {
          final c = line.codeUnitAt(j);
          if (c != 32) {
            break;
          }
        }

        if (indent == null) {
          indent = j;
        } else if (indent > j) {
          indent = j;
        }
      }

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        code.add(line.substring(indent));
      }
    }

    final action = ActionOperation(variables.values.map(varOp).toList(), code);
    b.operations.add(action);
    addAssign(b, varOp(result), varOp($$));
  }
}
