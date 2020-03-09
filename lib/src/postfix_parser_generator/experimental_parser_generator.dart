part of '../../postfix_parser_generator.dart';

class ExperimentalParserGenerator with OperationUtils {
  final Grammar grammar;

  final ParserClassMembers m = ParserClassMembers();

  MemberAllocator ma;

  final ParserGeneratorOptions options;

  StateAllocator sa;

  ExperimentalParserGenerator(this.grammar, this.options);

  void generate(
      List<MethodOperation> methods, List<ParameterOperation> paramters) {
    final rules = grammar.rules;
    for (final rule in rules) {
      _genRule(rule);
    }
  }

  void _addGoto(BlockOperation block, int state) {
    addAssign(block, varOp(m.state), constOp(state));
    addBreak(block);
  }

  void _addPushState(BlockOperation block, int state) {
    final stack = varOp(m.stateStack);
    final stateSp = varOp(m.stateSp);
    final index = postDecOp(stateSp);
    final stackAccess = ListAccessOperation(stack, index);
    addAssign(block, stackAccess, constOp(state));
  }

  void _addReturn(BlockOperation block) {
    final index = preDecOp(varOp(m.stateSp));
    final stack = listAccOp(varOp(m.stateStack), index);
    addAssign(block, varOp(m.success), stack);
  }

  void _checkBlockIsEmpty(BlockOperation block) {
    if (block.operations.isNotEmpty) {
      throw StateError('Block is not empty');
    }
  }

  int _genCall(
      int start, int callee, Operation resultSender, Operation resultReceiver) {
    final block = sa.getBlock(start);
    final assigner = sa.allocate();
    final assignerBlock = sa.getBlock(assigner);
    final next = sa.allocate();
    _addPushState(block, assigner);
    _addGoto(block, callee);
    addAssign(assignerBlock, resultReceiver, resultSender);
    _addGoto(assignerBlock, next);
    return next;
  }

  int _genExpr(Expression node) {
    final startState = sa.getState(node);
    final startBlock = sa.getBlock(startState);
    _checkBlockIsEmpty(startBlock);
    if (node is AnyCharacterExpression) {
      //
    } else if (node is AndPredicateExpression) {
      //
    } else if (node is AndPredicateExpression) {
      //
    } else if (node is CaptureExpression) {
      //
    } else if (node is CharacterClassExpression) {
      //
    } else if (node is LiteralExpression) {
      //
    } else if (node is NotPredicateExpression) {
      //
    } else if (node is NonterminalExpression) {
      //
    } else if (node is OneOrMoreExpression) {
      //
    } else if (node is OptionalExpression) {
      final child = node.expression;
      _genExpr(child);
      final result = ma.getFieldOperation(node);
      final entry = _genExprCall(startState, child, result);
      final entryBlock = sa.getBlock(entry);
      addAssign(entryBlock, varOp(m.success), constOp(true));
    } else if (node is OrderedChoiceExpression) {
      //
    } else if (node is SequenceExpression) {
      //
    } else if (node is SubterminalExpression) {
      //
    } else if (node is TerminalExpression) {
      //
    } else if (node is ZeroOrMoreExpression) {
      final child = node.expression;
      _genExpr(child);
      final result = ma.getFieldOperation(node);
      final returnType = node.returnType;
      final loopGenerator = LoopGenerator(sa, _addGoto);
      loopGenerator.generate(startState, (g, block) {
        g.addCall((b) => _genExprCall(b, child, result));
        g.addBlock((block) {
          final list = listOp(returnType, []);
          addAssign(block, result, list);
          addIfNotVar(block, m.success, (block) {
            g.addBreak(block);
          });

          addAssign(block, result, list);
        });
      });
    }

    return startState;
  }

  int _genExprCall(int start, Expression expression, Operation resultReceiver) {
    final callee = sa.getState(expression);
    final resultSender = ma.getFieldOperation(expression);
    return _genCall(start, callee, resultSender, resultReceiver);
  }

  void _genRule(ProductionRule rule) {
    final startState = sa.getState(rule);
    final startBlock = sa.getBlock(startState);
    _checkBlockIsEmpty(startBlock);
  }

  int _genRuleCall(BlockOperation block, SymbolExpression symbol,
      Operation resultReceiver, int afterReturn) {
    final choice = symbol.expression;
    final rule = choice.rule;
    final callee = sa.getState(rule);
    final resultSender = ma.getFieldOperation(symbol);
    return _genCall(block, callee, resultSender, resultReceiver);
  }
}

class BlockGenerator {
  int _end;

  final void Function(BlockOperation, int) _genGoto;

  bool _isWorkState = false;

  final StateAllocator _sa;

  final List<List<int>> _states = [];

  int generate(int start, void Function(BlockGenerator, BlockOperation) f) {
    if (_isWorkState) {
      throw StateError('The generator already is in work state');
    }

    _isWorkState = true;
    _end = _sa.allocate();
    f(this, null);
    int prev;
    for (final state in _states) {
      //
      prev = state;
    }

    _isWorkState = false;
    return _end;
  }

  int _getLast() {
    //
  }

  BlockGenerator(this._sa, this._genGoto);

  void addBlock(void Function(BlockOperation) f) {
    _checkIsWorkState();
    final start = _sa.allocate();
    final block = _sa.getBlock(start);
    
    _states.add([start, null]);
    f(block);
  }

  void addCall(int Function(int) f) {
    _checkIsWorkState();
    final start = _sa.allocate();
    final end = f(start);
    _states.add([start, end]);
  }

  void addPart(int prev, int next) {
    _checkIsWorkState();
    _states.add(prev);
    _states.add(next);
  }

  void _checkIsWorkState() {
    if (!_isWorkState) {
      throw StateError('The generator is not in work state');
    }
  }
}

class LoopGenerator {
  final void Function(BlockOperation, int) _addGoto;

  int _exit;

  final bool _isGenerated = false;

  final StateAllocator _sa;

  final List<int> states = [];

  LoopGenerator(this._sa, this._addGoto) {
    _exit = _sa.allocate();
  }

  int generate(int start, void Function(LoopGenerator, BlockOperation) f) {
    _checkNotGenerated();
    return _exit;
  }

  void addBlock(void Function(BlockOperation) f) {
    if (_isGenerated) {
      final state = _sa.allocate();
      final block = _sa.getBlock(state);
      states.add(state);
      f(block);
    }
  }

  void addBreak(BlockOperation block) {
    _checkNotGenerated();
    _addGoto(block, _exit);
  }

  void addCall(int Function(int) f) {
    _checkNotGenerated();
    states.add(start);
    final next = f(start);
    states.add(next);
  }

  void addPart(int prev, int next) {
    _checkNotGenerated();
    states.add(prev);
    states.add(next);
  }

  void _checkNotGenerated() {
    //
  }
}

class MemberAllocator {
  final Map<ProductionRule, Map<Expression, Variable>> _fields = {};

  final Map<ProductionRule, VariableAllocator> _fieldAllocators = {};

  final Map<ProductionRule, Variable> _ruleVariables = {};

  final Map<ProductionRule, List<Variable>> _variables = {};

  final Map<ProductionRule, VariableAllocator> _variableAllocators = {};

  Variable addVariable(Expression expression) {
    final rule = expression.rule;
    final variables = getVariables(rule);
    final va = _getVariableAllocator(rule);
    final result = va.alloc(true);
    variables.add(result);
    return result;
  }

  Variable getField(Expression expression) {
    final rule = expression.rule;
    final fields = getFields(rule);
    var result = fields[expression];
    if (result == null) {
      final va = _getFieldAllocator(rule);
      result = va.alloc(true);
      fields[expression] = result;
    }

    return result;
  }

  Operation getFieldOperation(Expression expression) {
    final fieldVariable = getField(expression);
    final field = VariableOperation(fieldVariable);
    final rule = expression.rule;
    final ruleVariable = getRuleVariable(rule);
    final owner = VariableOperation(ruleVariable);
    final result = MemberAccessOperation(owner, field);
    return result;
  }

  Map<Expression, Variable> getFields(ProductionRule rule) {
    var result = _fields[rule];
    if (result == null) {
      result = {};
      _fields[rule] = result;
    }

    return result;
  }

  Variable getRuleVariable(ProductionRule rule) {
    var result = _ruleVariables[rule];
    if (result == null) {
      result = Variable('\$r${rule.id}', true);
      _ruleVariables[rule] = result;
    }

    return result;
  }

  List<Variable> getVariables(ProductionRule rule) {
    var result = _variables[rule];
    if (result == null) {
      result = [];
      _variables[rule] = result;
    }

    return result;
  }

  VariableAllocator _getFieldAllocator(ProductionRule rule) {
    var result = _fieldAllocators[rule];
    if (result == null) {
      var id = 0;
      String allocate() {
        final name = '\f${id++}';
        return name;
      }

      result = VariableAllocator(allocate);
      _fieldAllocators[rule] = result;
    }

    return result;
  }

  VariableAllocator _getVariableAllocator(ProductionRule rule) {
    var result = _variableAllocators[rule];
    if (result == null) {
      var id = 0;
      String allocate() {
        final name = '\v${id++}';
        return name;
      }

      result = VariableAllocator(allocate);
      _variableAllocators[rule] = result;
    }

    return result;
  }
}

class ParserClassMembers {
  final c = Variable('_c', true);

  final input = Variable('_input', true);

  final pos = Variable('_pos', true);

  final state = Variable('_state', true);

  final stateSp = Variable('_stateSp', true);

  final stateStack = Variable('_stateStack', true);

  final success = Variable('_success', true);
}

class StateAllocator {
  int _id = 0;

  Map<int, BlockOperation> blocks;

  Map<Object, int> states;

  int allocate([Object object]) {
    if (object != null) {
      final state = states[object];
      if (state != null) {
        return state;
      }
    }

    final result = _id++;
    if (object != null) {
      states[object] = result;
    }

    final block = BlockOperation();
    blocks[result] = block;
    return result;
  }

  BlockOperation getBlock(int state) {
    final result = blocks[state];
    if (result == null) {
      throw StateError('Block not found');
    }

    return result;
  }

  int getState(Object object) {
    final result = states[object];
    if (result == null) {
      throw StateError('State not found');
    }

    return result;
  }
}
