part of '../../postfix_parser_generator.dart';

class PostfixProductionRulesGenerator
    extends ExpressionsToOperationsGenerator<PostfixParseClassMembers>
    with ExpressionVisitor, OperationUtils, ProductionRulesGenerator {
  final Grammar grammar;

  ParserGeneratorOptions options;

  bool _isPrefix;

  Map<SequenceExpression, MethodOperation> _methods;

  String _paramaterPrefix = '_paramaterPrefix';

  Variable _result;

  var _sequenceMethodVariables = <SequenceExpression, Variable>{};

  PostfixProductionRulesGenerator(this.grammar, this.options)
      : super(PostfixParseClassMembers());

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    _methods = {};
    _sequenceMethodVariables = {};
    final rules = grammar.rules;
    for (final rule in rules) {
      final method = _generateRule(rule);
      methods.add(method);
    }

    methods.addAll(_methods.values);
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final result = va.newVar(b, 'final', null);
      context.result = result;
    } else {
      super.visitAndPredicate(node);
    }
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final c = context.getAlias(m.c);
      final result = va.newVar(b, 'final', varOp(c));
      context.result = result;
    } else {
      super.visitAnyCharacter(node);
    }
  }

  @override
  void visitCapture(CaptureExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final c = context.getAlias(m.c);
      final result = va.newVar(b, 'final', varOp(c));
      context.result = result;
      throw null;
    } else {
      super.visitCapture(node);
    }
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final c = context.getAlias(m.c);
      final result = va.newVar(b, 'final', varOp(c));
      context.result = result;
    } else {
      super.visitCharacterClass(node);
    }
  }

  @override
  void visitLiteral(LiteralExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final text = node.text;
      final runes = text.runes.toList();
      if (runes.isEmpty) {
        final result = va.newVar(b, 'final', constOp(''));
        context.result = result;
      } else if (runes.length == 1) {
        final result = va.newVar(b, 'final', constOp(text));
        context.result = result;
      } else {
        final matchString = callOp(varOp(m.matchString), [constOp(text)]);
        final result = va.newVar(b, 'final', matchString);
        context.result = result;
      }
    } else {
      super.visitLiteral(node);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbolExpression(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    if (_isPrefix) {
      final b = context.block;
      addAssign(b, varOp(m.success), constOp(false));
      final result = va.newVar(b, 'final', null);
      context.result = result;
    } else {
      super.visitNotPredicate(node);
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final list = listOp(null, [varOp(_result)]);
      final result = va.newVar(b, 'final', list);
      context.result = result;
      addLoop(b, (b) {
        final child = node.expression;
        _isPrefix = false;
        final next = visitChild(child, b, context);
        _isPrefix = true;
        addIfNotVar(b, m.success, addBreak);
        final add = Variable('add');
        addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
      });
    } else {
      super.visitOneOrMore(node);
    }
  }

  @override
  void visitOptional(OptionalExpression node) {
    if (_isPrefix) {
      final b = context.block;
      final result = va.newVar(b, 'final', varOp(_result));
      context.result = result;
      addAssign(b, varOp(m.success), constOp(false));
    } else {
      super.visitOptional(node);
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (_isPrefix) {
      return;
    }

    final b = context.block;
    final c = context.saveVariable(b, va, m.c);
    final pos = context.saveVariable(b, va, m.pos);
    final expressionChainResolver = ExpressionChainResolver();
    final root = expressionChainResolver.resolve(node);
    final choices = _flattenNode(root);
    final transitions = SparseList<List<int>>();
    final epsilons = <int>[];
    _computeTransitions(choices, transitions, epsilons);
    final testC = lteOp(varOp(m.c), constOp(0xffff));
    final ternary = ternaryOp(testC, constOp(1), constOp(2));
    final assignPos = addAssignOp(varOp(m.pos), ternary);
    final listAcc = listAccOp(varOp(m.input), assignPos);
    addAssign(b, varOp(m.c), listAcc);
    if (choices.length > 1) {
      addLoop(b, (b) {
        final list = SparseList<List<int>>();
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

          list.addGroup(dest);
        }

        Variable transitionVariable;
        if (useStates) {
          transitionVariable = Variable('STATE');
        } else {
          transitionVariable = c;
        }

        for (final transition in list.groups) {
          final ranges = SparseBoolList();
          final group =
              GroupedRangeList<bool>(transition.start, transition.end, true);
          ranges.addGroup(group);
          final test =
              createTestOperationForRanges(transitionVariable, ranges, false);
          addIfElse(b, test, (b) {
            addAssign(b, varOp(m.success), constOp(true));
            for (final i in transition.key) {
              final choice = choices[i];
              for (final expression in choice) {
                _isPrefix = true;
                final next = visitChild(expression, b, context);
                _isPrefix = false;
                _result = next.result;
              }
            }

            addIfVar(b, m.success, (h) {
              // TODO: Restore variables
              final b = context.block;
              final result = va.newVar(b, 'final', varOp(_result));
              context.result = result;
              addBreak(b);
            });
          });
        }

        if (epsilons.isNotEmpty) {
          addAssign(b, varOp(m.success), constOp(false));
          for (final i in epsilons) {
            final choice = choices[i];
            for (final expression in choice) {
              _isPrefix = true;
              final next = visitChild(expression, b, context);
              _isPrefix = false;
              _result = next.result;
            }
          }

          addIfVar(b, m.success, addBreak);
        }
      });
    } else {
      // TODO: Make correction!!!
      final choice = choices.first;
      final c = context.getAlias(m.c);
      final ranges = SparseBoolList();
      for (final src in transitions.groups) {
        final dest = GroupedRangeList<bool>(src.start, src.end, true);
        ranges.addGroup(dest);
      }

      testRanges(b, c, ranges, false, (b) {
        for (final expression in choice) {
          _isPrefix = true;
          final next = visitChild(expression, b, context);
          _isPrefix = false;
          _result = next.result;
        }
      });

      _generateUnsuccessfulChoices(b, choices, epsilons);
    }

    final result = va.newVar(b, 'final', varOp(_result));
    context.result = result;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    if (expressions.length == 1) {
      final b = context.block;
      final hasAction = node.actionSource != null;
      if (!hasAction) {
        final result = va.newVar(b, 'final', varOp(_result));
        context.result = result;
        return;
      }
    }

    final b = context.block;
    final returnType = node.returnType;
    final func = _getSequenceMethodVariable(node);
    final method = MethodOperation(returnType, func.name, [], BlockOperation());
    _methods[node] = method;
    addCall(b, varOp(func), [varOp(_result)]);
    final prev = context;
    context = context.copy(b, copyAliases: false);
    generateSequence(node, isPostfix: true);
    prev.result = context.result;
    context = prev;
  }

  Variable _getSequenceMethodVariable(SequenceExpression expression) {
    var result = _sequenceMethodVariables[expression];
    if (result == null) {
      final name = _getExpressionMethodName(expression);
      result = Variable(name, true);
      _sequenceMethodVariables[expression] = result;
    }

    return result;
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
    if (_isPrefix) {
      final b = context.block;
      final list = listOp(null, [varOp(_result)]);
      final result = va.newVar(b, 'final', list);
      context.result = result;
      addLoop(b, (b) {
        final child = node.expression;
        _isPrefix = false;
        final next = visitChild(child, b, context);
        _isPrefix = true;
        addIfNotVar(b, m.success, addBreak);
        final add = Variable('add');
        addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
      });
    } else {
      super.visitZeroOrMore(node);
    }
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

  MethodOperation _generateRule(ProductionRule rule) {
    va = newVarAlloc();
    final body = BlockOperation();
    final context = ProductionRulesGeneratorContext(body);
    final expression = rule.expression;
    final callerId = context.addArgument(parameterCallerId, va.alloc(true));
    final productive = context.addArgument(parameterProductive, va.alloc(true));
    final name = _getMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', callerId));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;
    _isPrefix = false;

    void generate() {
      final b = context.block;
      final result = va.newVar(b, returnType, null);
      context.result = result;
      final next = visitChild(expression, b, context);
      addAssign(b, varOp(result), varOp(next.result));
      addReturn(b, varOp(result));
    }

    generate();
    final result = MethodOperation(returnType, name, params, body);
    return result;
  }

  void _generateUnsuccessfulChoices(
    BlockOperation block,
    List<List<Expression>> choices,
    List<int> epsilon,
  ) {
    final b = block;
    if (epsilon.isNotEmpty) {
      addAssign(b, varOp(m.success), constOp(false));
      addIfNotVar(b, m.success, (b) {
        for (final i in epsilon) {
          final choice = choices[i];
          for (var i = 1; i < choice.length; i++) {
            final expression = choice[i];
            final returnType = expression.returnType;
            _result = va.newVar(b, returnType, null);
            _isPrefix = true;
            final next = visitChild(expression, b, context);
            _result = next.result;
          }
        }
      });
    }
  }

  String _getExpressionMethodName(Expression expression) {
    final id = expression.id;
    final name = '_e$id';
    return name;
  }

  String _getMethodName(ProductionRule rule) {
    final expression = rule.expression;
    return _getExpressionMethodName(expression);
  }

  void _visitSymbolExpression(SymbolExpression node) {
    final b = context.block;
    final rule = node.expression.rule;
    var returnType = rule.returnType;
    final expression = rule.expression;
    returnType ??= expression.returnType;
    final name = Variable(_getExpressionMethodName(node));
    final parameters = [constOp(0), constOp(true)];
    final call = callOp(varOp(name), parameters);
    final result = va.newVar(b, returnType, call);
    context.result = result;
  }
}
