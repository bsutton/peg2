part of '../../postfix_parser_generator.dart';

class PostfixProductionRulesGenerator
    extends ExpressionsToOperationsGenerator<PostfixParseClassMembers>
    with ExpressionVisitor, OperationUtils, ProductionRulesGenerator {
  final Grammar grammar;

  ParserGeneratorOptions options;

  Variable _result;

  PostfixProductionRulesGenerator(this.grammar, this.options)
      : super(PostfixParseClassMembers());

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    final rules = grammar.rules;
    for (final rule in rules) {
      _generateRule(rule);
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_result != null) {
      context.result = va.newVar(b, 'final', null);
    } else {
      super.visitAndPredicate(node);
    }
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_mode == _Mode.start) {
      var c = context.tryGetVariable(m.c);
      c ??= m.c;
      final result = va.newVar(b, 'final', varOp(c));
      context.result = result;
    } else if (_mode == null) {
      super.visitAnyCharacter(node);
    } else {
      _errorInvalidMode(_mode);
    }
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_mode == _Mode.start) {
      var c = context.tryGetVariable(m.c);
      c ??= m.c;
      final result = va.newVar(b, 'final', varOp(c));
      context.result = result;
    } else if (_mode == null) {
      super.visitCharacterClass(node);
    } else {
      _errorInvalidMode(_mode);
    }
  }

  @override
  void visitLiteral(LiteralExpression node) {
    if (_mode == _Mode.start) {
      super.visitLiteral(node);
    } else if (_mode == null) {
      super.visitLiteral(node);
    } else {
      _errorInvalidMode(_mode);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbolExpression(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_result != null) {
      addAssign(b, varOp(m.success), constOp(false));
      context.result = va.newVar(b, 'final', null);
    } else {
      super.visitNotPredicate(node);
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_isPrologue) {
      final list = listOp(null, [xxx]);
      final result = va.newVar(b, 'final', list);
      context.result = result;
      addLoop(b, (b) {
        final child = node.expression;
        final next = visitChild(child, b, context);
        addIfNotVar(b, m.success, addBreak);
      });
    } else {
      super.visitOneOrMore(node);
    }
  }

  @override
  void visitOptional(OptionalExpression node) {
    final context = contexts.last;
    final b = context.block;
    if (_result != null) {
      addAssign(b, varOp(m.success), constOp(false));
      context.result = va.newVar(b, 'final', null);
    } else {
      super.visitOptional(node);
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final context = contexts.last;
    final b = context.block;
    final expressions = node.expressions;
    final expressionChainResolver = ExpressionChainResolver();
    final root = expressionChainResolver.resolve(node);
    final choices = _flattenNode(root);
    addLoop(b, (b) {
      //
    });
  }

  @override
  void visitSequence(SequenceExpression node) {
    //
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
    final context = contexts.last;
    final b = context.block;
    if (_isPrologue) {
      throw StateError('Prologue is not supported');
    } else if (_isEpilogue) {
      throw StateError('Epilogue is not supported');
    } else {
      super.visitZeroOrMore(node);
    }
  }

  void _errorInvalidMode(_Mode mode) {
    throw StateError('Invalid mode');
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
    final name = _getRuleMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', callerId));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;

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

  Map<String, Variable> _getData(Expression expression) {
    var result = _data[expression];
    if (result == null) {
      result = {};
      _data[expression] = result;
    }

    return result;
  }

  String _getExpressionMethodName(Expression expression) {
    final id = expression.id;
    final name = '_e$id';
    return name;
  }

  String _getRuleMethodName(ProductionRule rule) {
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
