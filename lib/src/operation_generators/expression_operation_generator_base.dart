part of '../../operation_generators.dart';

abstract class ExpressionOperationGeneratorBase extends ExpressionVisitor
    with OperationUtils, ProductionRuleUtils {
  BlockOperation block;

  Variable callerId;

  bool isProductive = true;

  final ParserClassMembers m = ParserClassMembers();

  final ParserGeneratorOptions options;

  Variable productive;

  Variable result;

  final VariableAllocator va;

  final _savedVariables = <int, Map<Variable, Variable>>{};

  int _sessionId = 0;

  ExpressionOperationGeneratorBase(this.options, this.block, this.va);

  int getSession() {
    return _sessionId++;
  }

  void restoreVariables(int session) {
    final variables = _getSessionVariables(session);
    for (final key in variables.keys) {
      final value = variables[key];
      addAssign(block, varOp(key), varOp(value));
    }
  }

  void runInBlock(BlockOperation block, void Function() f) {
    final prev = this.block;
    this.block = block;
    f();
    this.block = prev;
  }

  Variable saveVariable(int session, Variable variable) {
    final variables = _getSessionVariables(session);
    if (variables.containsKey(variable)) {
      throw StateError('Variable already saved: ${variable}');
    }

    final result = va.newVar(block, 'final', varOp(variable));
    variables[variable] = result;
    return result;
  }

  void visitChild(
      ExpressionVisitor visitor, Expression node, BlockOperation block) {
    runInBlock(block, () => node.accept(visitor));
  }

  Map<Variable, Variable> _getSessionVariables(int session) {
    var result = _savedVariables[session];
    if (result == null) {
      result = {};
      _savedVariables[session] = result;
    }

    return result;
  }
}
