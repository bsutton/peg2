part of '../../operation_optimizers.dart';

class VariableUsageOptimizer with OperationUtils {
  void optimize(BlockOperation operation) {
    final usedBelow = <Variable>{};
    final operations = operation.operations;
    for (var i = operations.length - 1; i >= 0; i--) {
      final current = operations[i];
      final binary = _getOp<BinaryOperation>(current);
      if (binary == null || binary.kind != OperationKind.assign) {
        usedBelow.addAll(current.variablesUsage.readings.keys);
        switch (current.kind) {
          case OperationKind.block:
            final op = _getOp<BlockOperation>(current);
            optimize(op);
            break;
          case OperationKind.conditional:
            final op = _getOp<ConditionalOperation>(current);
            optimize(op.ifTrue);
            if (op.ifFalse != null) {
              optimize(op.ifFalse);
            }

            break;
          case OperationKind.loop:
            final op = _getOp<LoopOperation>(current);
            optimize(op.body);
            break;
          default:
        }

        continue;
      }

      final left = _getOp<VariableOperation>(binary.left);
      final right = _getOp<VariableOperation>(binary.right);
      if (left == null || right == null) {
        usedBelow.addAll(current.variablesUsage.readings.keys);
        continue;
      }

      final leftVariable = left.variable;
      final rightVariable = right.variable;
      if (usedBelow.contains(rightVariable)) {
        continue;
      }

      final rightDeclaration = rightVariable.declaration;
      if (rightDeclaration == null || rightDeclaration.frozen) {
        continue;
      }

      final leftDeclaration = leftVariable.declaration;
      if (leftDeclaration == null || leftDeclaration.frozen) {
        continue;
      }

      final rightDeclarationParent = rightDeclaration.parent;
      if (_isVariableUsedInOperation(rightDeclarationParent, leftVariable)) {
        usedBelow.add(rightVariable);
        continue;
      }

      final variableReplacer = _VariableReplacer();
      variableReplacer.replace(
          rightDeclarationParent, rightVariable, leftVariable);

      _replaceParameter(rightDeclaration, leftVariable);

      //final assign = binOp(OperationKind.assign, varOp(leftVariable), varOp(leftVariable));
      _replaceAssign(binary, NopOperation('${leftVariable} = ${rightVariable}'));
      final variableUsageResolver = VariablesUsageResolver();
      variableUsageResolver.resolve(rightDeclarationParent);
    }
  }

  T _getOp<T extends Operation>(Operation operation) {
    if (operation is T) {
      return operation;
    }

    return null;
  }

  bool _isVariableUsedInOperation(Operation operation, Variable variable) {
    final variablesUsage = operation.variablesUsage;
    final readCount = variablesUsage.getReadCount(variable);
    final writeCount = variablesUsage.getWriteCount(variable);
    return readCount == 0 && writeCount == 0;
  }

  void _replaceParameter(ParameterOperation parameter, Variable variable) {
    final operation = parameter.operation;
    if (operation == null) {
      _replaceOperation(parameter, NopOperation());
    } else {
      final assign = binOp(OperationKind.assign, varOp(variable), operation);
      _replaceOperation(parameter, assign);
    }
  }

  void _replaceAssign(BinaryOperation from, Operation to) {
    _replaceOperation(from, to);
  }

  void _replaceOperation(Operation from, Operation to) {
    final operationReplacer = OperationReplacer();
    operationReplacer.replace(from, to);
  }
}

class _VariableReplacer extends SimpleOperationVisitor {
  Variable _from;

  Variable _to;

  void replace(Operation operation, Variable from, Variable to) {
    _from = from;
    _to = to;
    operation.accept(this);
  }

  @override
  void visitVariable(VariableOperation node) {
    if (node.variable == _from) {
      node.variable = _to;
    }
  }
}
