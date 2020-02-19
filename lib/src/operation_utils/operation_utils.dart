part of '../../operation_utils.dart';

void addAssign(BlockOperation b, Operation left, Operation right) {
  final operation = BinaryOperation(left, OperationKind.assign, right);
  b.operations.add(operation);
}

void addBreak(BlockOperation b) {
  final op = BreakOperation();
  b.operations.add(op);
}

ConditionalOperation addIfElse(
    BlockOperation block, Operation test, void Function(BlockOperation) ifTrue,
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

ConditionalOperation addIf(
    BlockOperation block, Operation test, void Function(BlockOperation) fTrue,
    [void Function(BlockOperation) fFalse]) {
  final bTrue = BlockOperation();
  BlockOperation bFalse;
  if (fFalse != null) {
    bFalse = BlockOperation();
  }

  final op = ConditionalOperation(test, bTrue, bFalse);
  block.operations.add(op);
  fTrue(bTrue);
  if (fFalse != null) {
    fFalse(bFalse);
  }

  return op;
}

LoopOperation addLoop(BlockOperation block, void Function(BlockOperation) f) {
  final body = BlockOperation();
  final op = LoopOperation(body);
  block.operations.add(op);
  if (f != null) {
    f(op.body);
  }

  return op;
}

void addMember(BlockOperation b, Operation member, Operation operation) {
  final op = MemberOperation(member, operation);
  b.operations.add(op);
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

void addReturn(BlockOperation b, Operation operation) {
  final op = ReturnOperation(operation);
  b.operations.add(op);
}

CallOperation call(Operation op, List<Operation> args) {
  return CallOperation(op, args);
}

ConstantOperation<T> constOp<T>(T value) {
  return ConstantOperation(value);
}

ConditionalOperation ifNotVar(BlockOperation block, Variable variable,
    void Function(BlockOperation) fTrue,
    [void Function(BlockOperation) fFalse]) {
  final test = UnaryOperation(OperationKind.not, varOp(variable));
  return addIf(block, test, fTrue, fFalse);
}

ConditionalOperation ifVar(BlockOperation block, Variable variable,
    void Function(BlockOperation) fTrue,
    [void Function(BlockOperation) fFalse]) {
  return addIf(block, varOp(variable), fTrue, fFalse);
}

Variable newVar(BlockOperation b, String type, Variable Function() allocVar,
    [Operation value]) {
  final variable = allocVar();
  final parameter = ParameterOperation(type, variable, value);
  b.operations.add(parameter);
  return variable;
}

void restoreVars(BlockOperation block, Map<Variable, Variable> variables) {
  for (final key in variables.keys) {
    addAssign(block, varOp(variables[key]), varOp(key));
  }
}

Map<Variable, Variable> saveVars(BlockOperation block,
    Variable Function() allocVar, List<Variable> identifiers) {
  final result = <Variable, Variable>{};
  for (final element in identifiers) {
    final variable = newVar(block, 'var', allocVar, varOp(element));
    result[variable] = element;
  }

  return result;
}

UnaryOperation unary(OperationKind kind, Operation op) {
  return UnaryOperation(kind, op);
}

VariableOperation varOp(Variable variable) {
  return VariableOperation(variable);
}
