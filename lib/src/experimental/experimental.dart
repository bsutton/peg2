part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionVisitor {
  BlockOperation _block;

  Variable _c;

  Variable _captures;

  Variable _cp;

  Variable _input;

  int _lastVariableIndex;

  Map<Expression, MethodOperation> _methodOperations;

  Map<String, Variable> _methodVariables;

  Variable _predicate;

  Variable _pos;

  Variable _productive;

  Variable _result;

  Variable _success;

  void generate(Grammar grammar) {
    _c = Variable('_c');
    _captures = Variable('_captures');
    _cp = Variable('_cp');
    _input = Variable('_input');
    _lastVariableIndex = 0;
    _methodOperations = {};
    _methodVariables = {};
    _predicate = Variable('_predicate');
    _pos = Variable('_pos');
    _success = Variable('_success');
    for (final rule in grammar.rules) {
      final expression = rule.expression;
      expression.accept(this);
    }

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
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final b = _block;
    if (node.index == 0) {
      final popState = Variable('_popState');
      addCall(b, varOp(popState), []);
      _result = newVar(b, 'var', _allocVar, null);
    } else {
      final child = node.expression;
      final state = saveVars(b, _allocVar, [
        _c,
        _cp,
        _pos,
        _predicate,
        _productive,
      ]);

      addAssign(b, varOp(_predicate), constOp(true));
      addAssign(b, varOp(_productive), constOp(false));
      child.accept(this);
      _result = newVar(b, 'var', _allocVar, null);
      restoreVars(b, state);
    }
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    if (node.index == 0) {
      return;
    }

    final matchAny = varOp(Variable('_matchAny'));
    final callMatchAny = callOp(matchAny, []);
    final result = newVar(_block, 'var', _allocVar, callMatchAny);
    _result = result;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final b = _block;
    if (node.index == 0) {
      final start = newVar(b, 'var', _allocVar, null);
      final pop = Variable('pop');
      final callPop = mbrCall(varOp(_captures), varOp(pop), []);
      addAssign(b, varOp(start), callPop);
      ifVar(b, _success, (b) {
        final result = newVar(b, 'String', _allocVar, null);
        final substring = Variable('substring');
        final callSubstring = mbrCall(
            varOp(_input), varOp(substring), [varOp(start), varOp(_pos)]);
        addAssign(b, varOp(result), callSubstring);
      });
    } else {
      final result = newVar(b, 'String', _allocVar, null);
      final start = newVar(b, 'var', _allocVar, varOp(_pos));
      final saved = saveVars(b, _allocVar, [_productive]);
      addAssign(b, varOp(_productive), constOp(false));
      node.expression.accept(this);
      ifVar(b, _success, (b) {
        final substring = Variable('substring');
        final callSubstring = mbrCall(
            varOp(_input), varOp(substring), [varOp(start), varOp(_pos)]);
        addAssign(b, varOp(result), callSubstring);
      });

      restoreVars(b, saved);
      _result = result;
    }

    final child = node.expression;
    child.accept(this);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    if (node.index == 0) {
      return;
    }

    final b = _block;
    final ranges = <int>[];
    var simple = true;
    for (final range in node.ranges) {
      final start = range[0];
      final end = range[1];
      ranges.add(start);
      ranges.add(end);
      if (start != end) {
        simple = false;
      }
    }

    Variable result;
    if (simple && ranges.length == 2) {
      final matchChar = Variable('_matchChar');
      final callMatchChar = callOp(varOp(matchChar), [constOp(ranges[0])]);
      result = newVar(b, 'var', _allocVar, callMatchChar);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(ConstantOperation(ranges[i]));
        elements.add(ConstantOperation(ranges[i + 1]));
      }

      final listOp = ListOperation(null, elements);
      final list = newVar(b, 'const', _allocVar, listOp);
      final matchRanges = Variable('_matchRanges');
      final callMatchRanges = callOp(varOp(matchRanges), [varOp(list)]);
      result = newVar(b, 'var', _allocVar, callMatchRanges);
    }

    _result = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    if (node.index == 0) {
      return;
    }

    throw null;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _callRule(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final b = _block;
    if (node.index == 0) {
      final popState = Variable('_popState');
      addCall(b, varOp(popState), []);
      _result = newVar(b, 'var', _allocVar, null);
      addAssign(
          b, varOp(_success), unaryOp(OperationKind.not, varOp(_success)));
    } else {
      final child = node.expression;
      final state = saveVars(b, _allocVar, [
        _c,
        _cp,
        _pos,
        _predicate,
        _productive,
      ]);

      addAssign(b, varOp(_predicate), constOp(true));
      addAssign(b, varOp(_productive), constOp(false));
      child.accept(this);
      _result = newVar(b, 'var', _allocVar, null);
      addAssign(
          b, varOp(_success), unaryOp(OperationKind.not, varOp(_success)));
      restoreVars(b, state);
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final b = _block;
    final returnType = node.returnType;
    final result = newVar(b, returnType, _allocVar, null);
    if (node.index == 0) {
      ifVar(b, _success, (b) {
        addIfElse(b, varOp(_productive), (b) {
          addAssign(b, varOp(result), ListOperation(null, []));
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(_result)]);
        });

        addLoop(b, (b) {
          _block = b;
          node.expression.accept(this);
          ifNotVar(b, _success, (b) {
            addAssign(_block, varOp(_success), constOp(true));
            addBreak(b);
          });

          addIfElse(b, varOp(_productive), (b) {
            final add = Variable('add');
            addMbrCall(b, varOp(result), varOp(add), [varOp(_result)]);
          });
        });
      });
    } else {
      addIfElse(b, varOp(_productive), (b) {
        addAssign(b, varOp(result), ListOperation(null, []));
      });

      final passed = newVar(b, 'var', _allocVar, constOp(false));
      addLoop(b, (b) {
        _block = b;
        node.expression.accept(this);
        ifNotVar(b, _success, (b) {
          addAssign(b, varOp(_success), varOp(passed));
          ifNotVar(b, _success, (b) {
            addAssign(b, varOp(result), constOp(null));
          });

          addBreak(b);
        });

        addIfElse(b, varOp(_productive), (b) {
          final add = Variable('add');
          addMbrCall(b, varOp(result), varOp(add), [varOp(_result)]);
        });

        addAssign(b, varOp(passed), constOp(true));
      });

      _result = result;
      _block = b;
    }
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    if (node.index == 0) {
      //
    } else {
      //
    }

    addAssign(_block, varOp(_success), constOp(true));
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final block = _block;
    final expressions = node.expressions;
    final method = _getMethodOperation(node, []);
    _block = method.body;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
    }

    _block = block;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final results = <Variable>[];
    _lastVariableIndex = 0;
    final arg0 = _allocVar();
    final returnType = node.returnType;
    final parameter = ParameterOperation(returnType, arg0);
    final method = _getMethodOperation(node, [parameter]);
    _block = method.body;
    _result = arg0;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      results.add(_result);
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _callRule(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _callRule(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    if (node.index == 0) {
      throw null;
    }

    final child = node.expression;
    child.accept(this);
  }

  Variable _allocVar() {
    final result = Variable('\$${_lastVariableIndex++}');
    return result;
  }

  void _callRule(SymbolExpression node) {
    if (node.index == 0) {
      return;
    } else {
      final variable = _getCallVar(node.rule.expression.index);
      final methodCall = callOp(variable, []);
      final result = newVar(_block, 'var', _allocVar, methodCall);
      _result = result;
    }
  }

  void _generateChoice(OrderedChoiceExpression expression) {
    final expressions = expression.expressions;

    final expressionChainResolver = ExpressionChainResolver();
    final node2 = expressionChainResolver.resolve(expression);

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
  }

  VariableOperation _getCallVar(int id) {
    final name = '_p$id';
    var variable = _methodVariables[name];
    if (variable == null) {
      variable = Variable(name);
      _methodVariables[name] = variable;
    }

    final operation = VariableOperation(variable);
    return operation;
  }

  MethodOperation _getMethodOperation(
      Expression expression, List<ParameterOperation> parameters) {
    var method = _methodOperations[expression];
    if (method == null) {
      final id = expression.id;
      final returnType = expression.returnType;
      final variable = _getCallVar(id);
      method = MethodOperation(returnType, variable.variable.name, parameters);
      _methodOperations[expression] = method;
    }

    return method;
  }
}
