part of '../../operation_generators.dart';

abstract class ExpressionToOperationGenerator extends ExpressionVisitor
    with OperationUtils {
  BlockOperation block;

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

  VariableAllocator varAlloc;

  ExpressionToOperationGenerator(this.options);

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

  VariableAllocator getLocalVarAlloc() {
    var lastVariableId = 0;
    final result = VariableAllocator(() {
      final name = '\$${lastVariableId++}';
      return name;
    });

    return result;
  }

  String getRuleMethodName(ProductionRule rule);

  Operation rangesToBinaryTest(List<int> ranges) {
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
    final b = block;
    final child = node.expression;
    final state = saveVars(b, varAlloc, [
      m.c,
      m.pos,
      m.predicate,
      productive,
    ]);

    addAssign(b, varOp(m.predicate), constOp(true));
    addAssign(b, varOp(productive), constOp(false));
    child.accept(this);
    final result = varAlloc.newVar(b, 'var', null);
    restoreVars(b, state);
    resultVar = result;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final b = block;
    final result = varAlloc.newVar(block, 'int', null);
    final test = ltOp(varOp(m.c), varOp(m.eof));
    addAssign(b, varOp(m.success), test);
    addIfElse(b, varOp(m.success), (b) {
      addAssign(b, varOp(result), varOp(m.c));
      final preInc = unaryOp(OperationKind.preInc, varOp(m.pos));
      final listAcc = ListAccessOperation(varOp(m.input), preInc);
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
    final b = block;
    final result = varAlloc.newVar(b, 'String', null);
    final start = varAlloc.newVar(b, 'var', varOp(m.pos));
    final saved = saveVars(b, varAlloc, [productive]);
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
    final b = block;
    final ranges = <int>[];
    for (final range in node.ranges) {
      ranges.addAll(range);
    }

    Variable result;
    if (ranges.length <= 20) {
      result = varAlloc.newVar(block, 'int', null);
      final test = rangesToBinaryTest(ranges);
      addIfElse(b, test, (b) {
        addAssign(b, varOp(m.success), constOp(true));
        addAssign(b, varOp(result), varOp(m.c));
        final preInc = unaryOp(OperationKind.preInc, varOp(m.pos));
        final listAcc = ListAccessOperation(varOp(m.input), preInc);
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
      final list = varAlloc.newVar(b, 'const', listOp);
      final matchRanges = callOp(varOp(m.matchRanges), [varOp(list)]);
      result = varAlloc.newVar(b, 'var', matchRanges);
    }

    resultVar = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final b = block;
    final text = node.text;
    final runes = text.runes;
    Variable result;
    if (runes.length == 1) {
      final rune = runes.first;
      result = varAlloc.newVar(b, 'String', null);
      final test = equalOp(varOp(m.c), constOp(rune));
      addAssign(b, varOp(m.success), test);
      addIfElse(b, varOp(m.success), (b) {
        addAssign(b, varOp(result), constOp(text));
        final preInc = unaryOp(OperationKind.preInc, varOp(m.pos));
        final listAcc = ListAccessOperation(varOp(m.input), preInc);
        addAssign(b, varOp(m.c), listAcc);
      }, (b) {
        final test = ltOp(varOp(m.fposEnd), varOp(m.pos));
        addIf(b, test, (b) {
          addAssign(b, varOp(m.fposEnd), varOp(m.pos));
        });
      });
    } else if (runes.length > 1) {
      final rune = runes.first;
      result = varAlloc.newVar(b, 'String', null);
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
      result = varAlloc.newVar(block, 'var', constOp(''));
      addAssign(b, varOp(m.success), constOp(true));
    }

    resultVar = result;
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final b = block;
    final child = node.expression;
    final state = saveVars(b, varAlloc, [
      m.c,
      m.pos,
      m.predicate,
      productive,
    ]);

    addAssign(b, varOp(m.predicate), constOp(true));
    addAssign(b, varOp(productive), constOp(false));
    child.accept(this);
    resultVar = varAlloc.newVar(b, 'var', null);
    addAssign(
        b, varOp(m.success), unaryOp(OperationKind.not, varOp(m.success)));
    restoreVars(b, state);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final b = block;
    final returnType = node.returnType;
    final result = varAlloc.newVar(b, returnType, null);
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), ListOperation(null, []));
      });
    } else {
      // Do nothing
    }

    final passed = varAlloc.newVar(b, 'var', constOp(false));
    addLoop(b, (b) {
      block = b;
      node.expression.accept(this);
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
    block = b;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final b = block;
    final child = node.expression;
    child.accept(this);
    addAssign(b, varOp(m.success), constOp(true));
  }

  @override
  void visitSequence(SequenceExpression node) {
    final b = block;
    final expressions = node.expressions;
    final hasAction = node.actionIndex != null;
    final variables = <Expression, Variable>{};
    Variable result;
    if (isPostfixGenerator) {
      final returnParam = findMethodParameter(node, paramReturn);
      result = returnParam.variable;
    } else {
      result = varAlloc.newVar(b, node.returnType, null);
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
      savedState = saveVars(b, varAlloc, [m.c, m.pos]);
    }

    final results = <Expression, Variable>{};
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      notProductive = !child.isProductive;
      void onExpression(BlockOperation b) {
        block = b;
        if (i == 0) {
          if (isPostfixGenerator) {
            final parameter = findMethodParameter(node, paramPostfix);
            resultVar = parameter.variable;
          } else {
            child.accept(this);
          }
        } else {
          child.accept(this);
        }

        results[child] = resultVar;
        if (child.variable != null) {
          variables[child] = resultVar;
        }
      }

      if (i == 0) {
        onExpression(block);
      } else {
        addIfVar(block, m.success, onExpression);
      }
    }

    if (hasSavedState) {
      onFailure = (b) {
        restoreVars(b, savedState);
      };
    }

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

    addIfVar(block, m.success, onSuccess);
    if (onFailure != null) {
      addIfNotVar(b, m.success, onFailure);
    }

    block = b;
    resultVar = result;
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final b = block;
    final returnType = node.returnType;
    final result = varAlloc.newVar(b, returnType, null);
    if (node.isProductive) {
      addIfElse(b, varOp(productive), (b) {
        addAssign(b, varOp(result), ListOperation(null, []));
      });
    } else {
      // Do nothing
    }

    addLoop(b, (b) {
      block = b;
      node.expression.accept(this);
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
    block = b;
  }

  void _buildAction(BlockOperation block, SequenceExpression node,
      Variable result, Map<Expression, Variable> variables) {
    for (final expression in variables.keys) {
      final variable = Variable(expression.variable);
      final parameter =
          ParameterOperation('var', variable, varOp(variables[expression]));
      block.operations.add(parameter);
    }

    final $$ = Variable('\$\$');
    final returnType = node.returnType;
    final parameter = ParameterOperation(returnType, $$);
    block.operations.add(parameter);
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
    block.operations.add(action);
    addAssign(block, varOp(result), varOp($$));
  }
}
