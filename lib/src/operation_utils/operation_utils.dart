part of '../../operation_utils.dart';

class OperationUtils {
  BinaryOperation addAssign(
      BlockOperation block, Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.assign, right);
    addOp(block, op);
    return op;
  }

  BreakOperation addBreak(BlockOperation block) {
    final op = BreakOperation();
    addOp(block, op);
    return op;
  }

  CallOperation addCall(
      BlockOperation block, Operation function, List<Operation> arguments) {
    final op = callOp(function, arguments);
    addOp(block, op);
    return op;
  }

  ConditionalOperation addIf(
      BlockOperation block, Operation test, void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    final bTrue = BlockOperation();
    BlockOperation bFalse;
    if (fFalse != null) {
      bFalse = BlockOperation();
    }

    final op = ConditionalOperation(test, bTrue, bFalse);
    addOp(block, op);
    fTrue(bTrue);
    if (fFalse != null) {
      fFalse(bFalse);
    }

    return op;
  }

  ConditionalOperation addIfElse(BlockOperation block, Operation test,
      void Function(BlockOperation) ifTrue,
      [void Function(BlockOperation) ifFalse]) {
    final bTrue = BlockOperation();
    BlockOperation bFalse;
    if (ifFalse != null) {
      bFalse = BlockOperation();
    }

    final op = ConditionalOperation(test, bTrue, bFalse);
    block.operations.add(op);
    ifTrue(bTrue);
    if (ifFalse != null) {
      ifFalse(bFalse);
    }

    return op;
  }

  LoopOperation addLoop(BlockOperation block, void Function(BlockOperation) f) {
    final b = BlockOperation();
    final op = LoopOperation(b);
    addOp(block, op);
    if (f != null) {
      f(op.body);
    }

    return op;
  }

  MemberOperation addMbrCall(BlockOperation block, Operation owner,
      VariableOperation method, List<Operation> arguments) {
    final op = mbrCallOp(owner, method, arguments);
    addOp(block, op);
    return op;
  }

  MemberOperation addMember(
      BlockOperation block, Operation owner, Operation member) {
    final op = MemberOperation(owner, member);
    addOp(block, op);
    return op;
  }

  MethodOperation addMethod(String type, String name,
      List<ParameterOperation> params, void Function(BlockOperation) f) {
    final body = BlockOperation();
    final op = MethodOperation(type, name, params, body);
    f(body);
    return op;
  }

  void addOp(BlockOperation block, Operation operation) {
    block.operations.add(operation);
  }

  void addReturn(BlockOperation block, Operation operation) {
    final op = ReturnOperation(operation);
    addOp(block, op);
  }

  CallOperation callOp(Operation function, List<Operation> arguments) {
    return CallOperation(function, arguments);
  }

  ConstantOperation<T> constOp<T>(T value) {
    return ConstantOperation(value);
  }

  ConditionalOperation addIfNotVar(BlockOperation block, Variable variable,
      void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    final test = UnaryOperation(OperationKind.not, varOp(variable));
    return addIf(block, test, fTrue, fFalse);
  }

  ConditionalOperation addIfVar(BlockOperation block, Variable variable,
      void Function(BlockOperation) fTrue,
      [void Function(BlockOperation) fFalse]) {
    return addIf(block, varOp(variable), fTrue, fFalse);
  }

  MemberOperation mbrCallOp(
      Operation owner, VariableOperation method, List<Operation> arguments) {
    final member = callOp(method, arguments);
    return mbrOp(owner, member);
  }

  MemberOperation mbrOp(Operation owner, Operation member) {
    final op = MemberOperation(owner, member);
    return op;
  }

  Variable newVar(BlockOperation block, String type, VariableAllocator varAlloc,
      Operation value) {
    final variable = varAlloc.alloc();
    final parameter = ParameterOperation(type, variable, value);
    addOp(block, parameter);
    return variable;
  }

  void restoreVars(BlockOperation block, Map<Variable, Variable> variables) {
    for (final key in variables.keys) {
      addAssign(block, varOp(variables[key]), varOp(key));
    }
  }

  Map<Variable, Variable> saveVars(BlockOperation block,
      VariableAllocator varAlloc, List<Variable> identifiers) {
    final result = <Variable, Variable>{};
    for (final element in identifiers) {
      final variable = newVar(block, 'var', varAlloc, varOp(element));
      result[variable] = element;
    }

    return result;
  }

  UnaryOperation unaryOp(OperationKind kind, Operation op) {
    return UnaryOperation(kind, op);
  }

  VariableOperation varOp(Variable variable) {
    return VariableOperation(variable);
  }
}
