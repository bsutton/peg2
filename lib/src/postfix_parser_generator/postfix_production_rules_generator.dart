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

  PostfixProductionRulesGenerator(this.grammar, this.options)
      : super(PostfixParseClassMembers());

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    _methods = {};
    final rules = grammar.rules;
    for (final rule in rules) {
      _generateRule(rule);
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
      super.visitLiteral(node);
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
        final next = visitChild(child, b, context);
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
      final b = context.block;
      final result = va.newVar(b, 'final', varOp(_result));
      context.result = result;
      return;
    }

    _isPrefix = true;
    final b = context.block;
    context.saveVariable(b, va, m.c);
    context.saveVariable(b, va, m.pos);
    final expressionChainResolver = ExpressionChainResolver();
    final root = expressionChainResolver.resolve(node);
    final choices = _flattenNode(root);
    final transitions = SparseList<List<int>>();
    final eofTransitions = <int>[];
    _computeTransitions(choices, transitions, eofTransitions);
    if (choices.length > 1) {
      addLoop(b, (b) {
        for (final transition in transitions.groups) {
          final ranges = SparseBoolList();
          final group =
              GroupedRangeList<bool>(transition.start, transition.end, true);
          ranges.addGroup(group);
          final c = context.getAlias(m.c);
          testRanges(b, c, ranges, false, (b) {
            for (final i in transition.key) {
              final choice = choices[i];
              for (final expression in choice) {
                final next = visitChild(expression, b, context);
                _result = next.result;
              }
            }
          });
        }
      });
    } else {
      final choice = choices.first;
      final c = context.getAlias(m.c);
      final ranges = SparseBoolList();
      for (final src in transitions.groups) {
        final dest = GroupedRangeList<bool>(src.start, src.end, true);
        ranges.addGroup(dest);
      }

      testRanges(b, c, ranges, false, (b) {
        for (final expression in choice) {
          final next = visitChild(expression, b, context);
          _result = next.result;
        }
      });

      if (eofTransitions.isNotEmpty) {
        addIfNotVar(b, m.success, (b) {
          for (final i in eofTransitions) {
            final choice = choices[i];
            for (final expression in choice) {
              final next = visitChild(expression, b, context);
              _result = next.result;
            }
          }
        });
      }
    }

    final result = va.newVar(b, 'final', varOp(context.result));
    context.result = result;
  }

  @override
  void visitSequence(SequenceExpression node) {
    ProductionRulesGeneratorContext visit(
        Expression expression,
        BlockOperation block,
        ProductionRulesGeneratorContext context,
        bool copyAliases) {
      final isFirst = expression.index == 0;
      if (isFirst) {
        final next = context.copy(block);
        next.result = Variable('XXX');
        return next;
      } else {
        return visitChild(expression, block, context, copyAliases: copyAliases);
      }
    }

    bool isOptional(Expression expression) {
      final isFirst = expression.index == 0;
      return expression.isOptional || isFirst;
    }

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

    generateSequence(node, visit, isOptional);
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
        final next = visitChild(child, b, context);
        addIfNotVar(b, m.success, addBreak);
        final add = Variable('add');
        addMbrCall(b, varOp(result), varOp(add), [varOp(next.result)]);
      });
    } else {
      super.visitZeroOrMore(node);
    }
  }

  void _computeTransitions(List<List<Expression>> choices,
      SparseList<List<int>> transitions, List<int> eofTransitions) {
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
        eofTransitions.add(i);
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
    /*
    final rule = node.expression.rule;
    var returnType = rule.returnType;
    final expression = rule.expression;
    returnType ??= rule.expression.returnType;
    final name = _getMethodVariable(expression);
    final parameters = [constOp(0), constOp(true)];
    final call = callOp(varOp(name), parameters);
    final result = _va.newVar(b, returnType, call);
    resultVar = result;
    */
  }
}
