part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionVisitor {
  BlockOperation _block;

  Map<OrderedChoiceExpression, MethodOperation> _choices;

  Expression _startExpression;

  Map<Expression, Expression> _startExpressions;

  int _lastVariableIndex;

  Map<String, int> _methodIs;

  Map<String, Variable> _methods;

  Variable _result;

  Map<SequenceExpression, MethodOperation> _sequences;

  Variable _success;

  void generate(Grammar grammar) {
    _startExpressions = {};
    _choices = {};
    _lastVariableIndex = 0;
    _methodIs = {};
    _methods = {};
    _sequences = {};
    _success = Variable('_success');
    for (final rule in grammar.rules) {
      final expression = rule.expression;
      expression.accept(this);
    }

    final expressionChainResolver = ExpressionChainResolver();
    final node = expressionChainResolver.resolve(grammar.start);

    var ident = 0;
    void visit(_Node node) {
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

    visit(node);
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    if (_startExpression == null) {
      _setStartExpression(node);
      return;
    }

    final matchAny = varOp(Variable('_matchAny'));
    final methodCall = call(matchAny, []);
    final result = newVar(_block, 'var', _allocVar, methodCall);
    _result = result;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    child.accept(this);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    if (_startExpression == null) {
      _setStartExpression(node);
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

    CallOperation methodCall;
    Variable result;
    if (simple && ranges.length == 2) {
      final matchChar = Variable('_matchChar');
      methodCall = call(varOp(matchChar), [constOp(ranges[0])]);
      result = newVar(b, 'var', _allocVar, methodCall);
    } else {
      final elements = <ConstantOperation>[];
      for (var i = 0; i < ranges.length; i += 2) {
        elements.add(ConstantOperation(ranges[i]));
        elements.add(ConstantOperation(ranges[i + 1]));
      }

      final listOp = ListOperation(null, elements);
      final list = newVar(b, 'const', _allocVar, listOp);
      final matchRanges = Variable('_matchRanges');
      methodCall = call(varOp(matchRanges), [varOp(list)]);
      result = newVar(b, 'var', _allocVar, methodCall);
    }

    _result = result;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    if (_startExpression == null) {
      _setStartExpression(node);
      return;
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _callRule(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    if (node.index == 0) {
      //
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    addAssign(_block, varOp(_success), constOp(true));
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (_startExpression == null) {
      _setStartExpression(node);
    }

    final block = _block;
    final expressions = node.expressions;
    final method = _getChoiceMethod(node);
    _block = method.body;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
    }

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

    _block = block;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final results = <Variable>[];
    final returnType = node.returnType;
    _lastVariableIndex = 0;
    final arg0 = _allocVar();
    final block = BlockOperation();
    _block = block;
    _result = arg0;
    _startExpression = null;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      results.add(_result);
    }

    _startExpressions[node] = _startExpression;
    final parameter = ParameterOperation(_startExpression.returnType, arg0);
    final method = _allocMethod('_parserSeq', returnType, [parameter], block);
    _sequences[node] = method;
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
    final child = node.expression;
    child.accept(this);
  }

  MethodOperation _allocMethod(
      String prefix, String returnType, List<ParameterOperation> parameters,
      [BlockOperation block]) {
    var id = _methodIs[prefix];
    if (id == null) {
      _methodIs[prefix] = 0;
      id = 0;
    }

    _methodIs[prefix]++;
    final name = '${prefix}$id';
    _methods[name] = Variable(name);
    return MethodOperation(returnType, name, parameters, block);
  }

  Variable _allocVar() {
    final result = Variable('\$${_lastVariableIndex++}');
    return result;
  }

  void _callRule(SymbolExpression node) {
    if (_startExpression == null) {
      _setStartExpression(node);
      return;
    }

    final method = _getChoiceMethod(node.rule.expression);
    final name = method.name;
    final methodCall = call(varOp(_methods[name]), []);
    final result = newVar(_block, 'var', _allocVar, methodCall);
    _result = result;
  }

  MethodOperation _getChoiceMethod(OrderedChoiceExpression node) {
    var method = _choices[node];
    if (method == null) {
      final returnType = node.returnType;
      method = _allocMethod('_parseChoice', returnType, []);
      _choices[node] = method;
    }

    return method;
  }

  void _setStartExpression(Expression node) {
    if (_startExpression != null) {
      throw StateError('Unable to set start expression');
    }

    _startExpression = node;
  }
}
