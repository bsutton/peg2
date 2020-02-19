part of '../../experimental.dart';

class ExperimentalGenerator extends ExpressionVisitor {
  BlockOperation _block;

  Map<Expression, Expression> _chain;

  Map<OrderedChoiceExpression, MethodOperation> _choices;

  Expression _startExpression;

  int _lastVariableIndex;

  Map<String, int> _methodIs;

  Map<String, Variable> _methods;

  Variable _result;

  Map<SequenceExpression, MethodOperation> _sequences;

  Variable _success;

  void generate(Grammar grammar) {
    _chain = {};
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

    for (final rule in grammar.rules) {
      final expression = rule.expression;
      for (final expr in expression.expressions) {
        var xxx = _chain[expr];
        while (true) {
          xxx = _chain[xxx];
          if (xxx == null) {
            break;
          }
        }
      }
    }
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

    _chain[node] = _startExpression;
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
