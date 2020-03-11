part of '../../postfix_parser_generator.dart';

class ExperimentalParserGenerator extends ParserGenerator with OperationUtils {
  final ParserClassMembers m = ParserClassMembers();

  _MemberAllocator ma;

  _StateAllocator sa;

  _StateBuilder sb;

  ExperimentalParserGenerator(Grammar grammar, ParserGeneratorOptions options)
      : super(grammar, options);

  @override
  void generateRules(
      List<MethodOperation> methods, List<ParameterOperation> paramters) {
    ma = _MemberAllocator();
    sa = _StateAllocator();
    var id = 0;
    final builders = <_StateBuilder>[];
    final helper = _MyStateHelper();
    final rules = grammar.rules;
    for (final rule in rules) {
      sb = _StateBuilder(helper, id);
      _genRule(rule);
      builders.add(sb);
      id = sb.id;
    }

    final body = BlockOperation();
    ConditionalOperation prev;
    for (final builder in builders) {
      for (final state in builder.states) {
        final test = eqOp(varOp(m.state), constOp(state.id));
        final current = ConditionalOperation(test, state.block);
        if (prev != null) {
          final block = BlockOperation();
          addOp(block, current);
          prev.ifFalse = block;
        } else {
          addOp(body, current);
        }

        prev != current;
      }
    }

    final method = MethodOperation('void', '_foo', [], body);
    methods.add(method);
  }

  void _genExpr(Expression node) {
    if (node is AndPredicateExpression) {
      final child = node.expression;
      final c = ma.addVariable(node, 'int');
      final pos = ma.addVariable(node, 'int');
      final productive = ma.addVariable(node, 'bool');
      addAssign(sb.block, c.op(), varOp(m.c));
      addAssign(sb.block, pos.op(), varOp(m.pos));
      addAssign(sb.block, productive.op(), varOp(m.productive));
      addAssign(sb.block, productive.op(), constOp(false));
      _genExpr(child);
      addAssign(sb.block, varOp(m.c), c.op());
      addAssign(sb.block, varOp(m.pos), pos.op());
      addAssign(sb.block, varOp(m.productive), productive.op());
      final result = ma.getFieldOperation(node);
      addAssign(sb.block, result.op(), constOp(null));
    } else if (node is AnyCharacterExpression) {
      //
    } else if (node is CaptureExpression) {
      final child = node.expression;
      _genExpr(child);
    } else if (node is CharacterClassExpression) {
      //
    } else if (node is LiteralExpression) {
      //
    } else if (node is NotPredicateExpression) {
      final child = node.expression;
      final c = ma.addVariable(node, 'int');
      final pos = ma.addVariable(node, 'int');
      final productive = ma.addVariable(node, 'bool');
      addAssign(sb.block, c.op(), varOp(m.c));
      addAssign(sb.block, pos.op(), varOp(m.pos));
      addAssign(sb.block, productive.op(), varOp(m.productive));
      addAssign(sb.block, productive.op(), constOp(false));
      _genExpr(child);
      addAssign(sb.block, varOp(m.success), notOp(varOp(m.success)));
      addAssign(sb.block, varOp(m.c), c.op());
      addAssign(sb.block, varOp(m.pos), pos.op());
      addAssign(sb.block, varOp(m.productive), productive.op());
      final result = ma.getFieldOperation(node);
      addAssign(sb.block, result.op(), constOp(null));
    } else if (node is NonterminalExpression) {
      //
    } else if (node is OneOrMoreExpression) {
      //
    } else if (node is OptionalExpression) {
      final child = node.expression;
      _genExpr(child);
      final childResult = ma.getFieldOperation(child);
      final result = ma.getFieldOperation(node);
      addAssign(sb.block, varOp(m.success), constOp(true));
      addAssign(sb.block, result.op(), childResult.op());
    } else if (node is OrderedChoiceExpression) {
      for (var child in node.expressions) {
        _genExpr(child);
      }
    } else if (node is SequenceExpression) {
      for (var child in node.expressions) {
        _genExpr(child);
      }
    } else if (node is SubterminalExpression) {
      //
    } else if (node is TerminalExpression) {
      //
    } else if (node is ZeroOrMoreExpression) {
      final child = node.expression;
      final childResult = ma.getFieldOperation(child);
      final result = ma.getFieldOperation(node);
      final isFirst = ma.addVariable(node, 'bool');
      final list = listOp(null, []);
      addAssign(sb.block, result.op(), list);
      addAssign(sb.block, isFirst.op(), constOp(true));
      final begin = sb.next();
      final exit = sb.label();
      _genExpr(child);
      addIfVar(sb.block, m.success, (block) {
        addIf(block, isFirst.op(), (block) {
          addAssign(block, result.op(), constOp(null));
        }, (block) {
          sb.addGoto(block, exit);
        });
      });

      addAssign(sb.block, isFirst.op(), constOp(false));
      final add = Variable('add');
      addMbrCall(sb.block, result.op(), varOp(add), [childResult.op()]);
      sb.addGoto(sb.block, begin);
      sb.state = exit;
    }
  }

  void _genRule(ProductionRule rule) {
    final expression = rule.expression;
    _genExpr(expression);
  }
}

class ParserClassMembers {
  final c = Variable('_c', true);

  final input = Variable('_input', true);

  final pos = Variable('_pos', true);

  final productive = Variable('_productive', true);

  final sp = Variable('_sp', true);

  final stack = Variable('_stack', true);

  final state = Variable('_state', true);

  final success = Variable('_success', true);
}

class _MemberAllocator {
  final Map<ProductionRule, Map<Expression, Variable>> _fields = {};

  final Map<ProductionRule, VariableAllocator> _fieldAllocators = {};

  final Map<ProductionRule, Variable> _ruleVariables = {};

  final Map<ProductionRule, List<_VariableAndType>> _variables = {};

  final Map<ProductionRule, VariableAllocator> _variableAllocators = {};

  _MemberOperationGenerator addVariable(Expression expression, String type) {
    final rule = expression.rule;
    final variables = getVariables(rule);
    final va = _getVariableAllocator(rule);
    final variable = va.alloc(true);
    final element = _VariableAndType(type, variable);
    variables.add(element);
    final result = getMemberOperation(expression, variable);
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

  _MemberOperationGenerator getFieldOperation(Expression expression) {
    final member = getField(expression);
    final rule = expression.rule;
    final owner = getRuleVariable(rule);
    final result = _MemberOperationGenerator(owner, member);
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

  _MemberOperationGenerator getMemberOperation(
      Expression expression, Variable variable) {
    final rule = expression.rule;
    final owner = getRuleVariable(rule);
    final result = _MemberOperationGenerator(owner, variable);
    return result;
  }

  Variable getRuleVariable(ProductionRule rule) {
    var result = _ruleVariables[rule];
    if (result == null) {
      result = Variable('_r${rule.id}', true);
      _ruleVariables[rule] = result;
    }

    return result;
  }

  List<_VariableAndType> getVariables(ProductionRule rule) {
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
        final name = 'f${id++}';
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
        final name = 'v${id++}';
        return name;
      }

      result = VariableAllocator(allocate);
      _variableAllocators[rule] = result;
    }

    return result;
  }
}

class _MemberOperationGenerator {
  final Variable member;

  final Variable owner;

  _MemberOperationGenerator(this.owner, this.member);

  Operation op() {
    final member = VariableOperation(this.member);
    final owner = VariableOperation(this.owner);
    final result = MemberAccessOperation(owner, member);
    return result;
  }
}

class _MyStateHelper extends _StateHelper {
  final ParserClassMembers _m = ParserClassMembers();

  final OperationUtils _utils = OperationUtils();

  @override
  void addGoto(BlockOperation block, _State state) {
    _utils.addAssign(block, _utils.varOp(_m.state), _utils.constOp(state.id));
    _utils.addBreak(block);
  }

  @override
  void addReturn(BlockOperation block) {
    final spDec = _utils.preDecOp(_utils.varOp(_m.sp));
    final stack = _utils.listAccOp(_utils.varOp(_m.stack), spDec);
    _utils.addAssign(block, _utils.varOp(_m.state), stack);
  }

  @override
  void callState(BlockOperation block, _StateBuilder builder, int state,
      List<Operation> arguments, Operation sender, Operation receiver) {
    // xxx
    addReturn(block);
    throw UnimplementedError();
  }
}

class _State {
  final BlockOperation block = BlockOperation();

  int id;

  _State(this.id);
}

class _StateAllocator {
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

class _StateBuilder {
  final _StateHelper helper;

  int id;

  _State state;

  final List<_State> states = [];

  _StateBuilder(this.helper, this.id) {
    state = _add();
  }

  BlockOperation get block => state.block;

  void addGoto(BlockOperation block, _State state) =>
      helper.addGoto(block, state);

  _State label() {
    final state = _add();
    return state;
  }

  _State next() {
    final next = _add();
    helper.addGoto(block, next);
    state = next;
    return state;
  }

  _State _add() {
    final state = _State(id++);
    states.add(state);
    return state;
  }
}

abstract class _StateHelper {
  void addGoto(BlockOperation from, _State to);

  void addReturn(BlockOperation block);

  void callState(BlockOperation block, _StateBuilder builder, int state,
      List<Operation> arguments, Operation sender, Operation receiver);
}

class _VariableAndType {
  final String type;

  final Variable variable;

  _VariableAndType(this.type, this.variable);
}
