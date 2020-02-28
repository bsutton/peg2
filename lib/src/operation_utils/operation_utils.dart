part of '../../operation_utils.dart';

class OperationUtils {
  BinaryOperation addAssign(
      BlockOperation block, Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.assign, right);
    addOp(block, op);
    return op;
  }

  BinaryOperation addAssignOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.addAssign, right);
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

  BinaryOperation binOp(OperationKind kind, Operation left, Operation right) {
    final op = BinaryOperation(left, kind, right);
    return op;
  }

  CallOperation callOp(Operation function, List<Operation> arguments) {
    return CallOperation(function, arguments);
  }

  ConstantOperation<T> constOp<T>(T value) {
    return ConstantOperation(value);
  }

  UnaryOperation convertOp(Operation op, String type) {
    return UnaryOperation(OperationKind.convert, op, type);
  }

  BinaryOperation equalOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.equal, right);
    return op;
  }

  T getOp<T extends Operation>(Operation operation) {
    if (operation is T) {
      return operation;
    }

    return null;
  }

  BinaryOperation gteOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.gte, right);
    return op;
  }

  BinaryOperation gtOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.gt, right);
    return op;
  }

  BinaryOperation landOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.land, right);
    return op;
  }

  ListAccessOperation listAccOp(Operation list, Operation index) {
    final op = ListAccessOperation(list, index);
    return op;
  }

  ListOperation listOp(String type, List<Operation> elements) {
    final op = ListOperation(type, elements);
    return op;
  }

  BinaryOperation lorOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.lor, right);
    return op;
  }

  BinaryOperation lteOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.lte, right);
    return op;
  }

  BinaryOperation ltOp(Operation left, Operation right) {
    final op = BinaryOperation(left, OperationKind.lt, right);
    return op;
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
    final parameter = paramOp(type, variable, value);
    addOp(block, parameter);
    return variable;
  }

  UnaryOperation notOp(Operation op) {
    return UnaryOperation(OperationKind.not, op);
  }

  ParameterOperation paramOp(
      String type, Variable variable, Operation operation) {
    return ParameterOperation(type, variable, operation);
  }

  UnaryOperation postDecOp(Operation op, [String type]) {
    return UnaryOperation(OperationKind.postDec, op, type);
  }

  UnaryOperation postIncOp(Operation op, [String type]) {
    return UnaryOperation(OperationKind.postInc, op, type);
  }

  UnaryOperation preDecOp(Operation op, [String type]) {
    return UnaryOperation(OperationKind.preDec, op, type);
  }

  UnaryOperation preIncOp(Operation op, [String type]) {
    return UnaryOperation(OperationKind.preInc, op, type);
  }

  void restoreVars(BlockOperation block, Map<Variable, Variable> variables) {
    for (final key in variables.keys) {
      addAssign(block, varOp(key), varOp(variables[key]));
    }
  }

  Map<Variable, Variable> saveVars(BlockOperation block,
      VariableAllocator varAlloc, List<Variable> identifiers) {
    final result = <Variable, Variable>{};
    for (final element in identifiers) {
      final variable = newVar(block, 'var', varAlloc, varOp(element));
      result[element] = variable;
    }

    return result;
  }

  TernaryOperation ternaryOp(
      Operation test, Operation ifTrue, Operation ifFalse) {
    final op = TernaryOperation(test, ifTrue, ifFalse);
    return op;
  }

  UnaryOperation unaryOp(OperationKind kind, Operation op, [String type]) {
    return UnaryOperation(kind, op, type);
  }

  VariableOperation varOp(Variable variable) {
    return VariableOperation(variable);
  }
}
