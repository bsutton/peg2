part of '../../operation_optimizers.dart';

class VariableOperationPropagator {
  void propagate(BlockOperation operation) {
    final used = <Variable>{};
    final operations = operation.operations;
    for (var i = operations.length - 1; i >= 0; i--) {
      final current = operations[i];
      final binary = _getOp<BinaryOperation>(current);
      if (binary == null || binary.kind != OperationKind.assign) {
        used.addAll(current.variablesUsage.readings.keys);
        switch (current.kind) {
          case OperationKind.block:
            final op = _getOp<BlockOperation>(current);
            propagate(op);
            break;
          case OperationKind.conditional:
            final op = _getOp<ConditionalOperation>(current);
            propagate(op.ifTrue);
            if (op.ifFalse != null) {
              propagate(op.ifFalse);
            }

            break;
          case OperationKind.loop:
            final op = _getOp<LoopOperation>(current);
            propagate(op.body);
            break;
          default:
        }

        continue;
      }

      final left = _getOp<VariableOperation>(binary.left);
      final right = _getOp<VariableOperation>(binary.right);
      if (left == null || right == null) {
        used.addAll(current.variablesUsage.readings.keys);
        continue;
      }

      final leftVariable = left.variable;
      final rightVariable = right.variable;
      if (used.contains(rightVariable)) {
        continue;
      }

      if (leftVariable.name == '_c') {
        var x = 0;
      }

      final declaration = rightVariable.declaration;
      if (declaration == null || declaration.frozen) {
        continue;
      }

      var failed = false;
      for (var j = i - 1; j >= 0; j--) {
        final current = operations[j];
        final variablesUsage = current.variablesUsage;
        final readCount = variablesUsage.getReadCount(leftVariable);
        final writeCount = variablesUsage.getWriteCount(leftVariable);
        if (readCount != 0 || writeCount != 0) {
          failed = true;
          break;
        }        
      }

      used.add(rightVariable);
      if (failed) {
        continue;
      }

      print('${leftVariable.name} = ${rightVariable.name}');

      for (var j = i - 1; j >= 0; j--) {
        final current = operations[j];
        final variableReplacer = _VariableReplacer();
        variableReplacer.replace(current, rightVariable, leftVariable);
      }

      final operationReplacer = OperationReplacer();
      operationReplacer.replace(current, NopOperation());
      if (declaration.parent == null) {
        throw StateError('Invalid parameter declaration');
      }

      final variableUsageResolver = VariableUsageResolver();
      variableUsageResolver.resolve(declaration.parent);
    }
  }

  T _getOp<T extends Operation>(Operation operation) {
    if (operation is T) {
      return operation;
    }

    return null;
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
