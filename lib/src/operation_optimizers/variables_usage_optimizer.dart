part of '../../operation_optimizers.dart';

class VariableUsageOptimizer with OperationUtils {
  VariablesStats _stats;

  void optimize(BlockOperation operation, VariablesStats stats) {
    _stats = stats;
    final used = <Variable>{};
    final operations = operation.operations;
    for (var i = operations.length - 1; i >= 0; i--) {
      final current = operations[i];
      final binary = getOp<BinaryOperation>(current);
      if (binary == null ||
          !(binary.kind == OperationKind.assign ||
              binary.kind == OperationKind.addAssign)) {
        final stat = _stats.getStat(current);
        switch (current.kind) {
          case OperationKind.block:
            final op = getOp<BlockOperation>(current);
            optimize(op, _stats);
            break;
          case OperationKind.conditional:
            final op = getOp<ConditionalOperation>(current);
            optimize(op.ifTrue, _stats);
            if (op.ifFalse != null) {
              optimize(op.ifFalse, _stats);
            }

            break;
          case OperationKind.loop:
            final op = getOp<LoopOperation>(current);
            optimize(op.body, _stats);
            break;
          default:
            used.addAll(stat.readings.keys);
        }

        continue;
      }

      final left = getOp<VariableOperation>(binary.left);
      final right = getOp<VariableOperation>(binary.right);
      final stat = _stats.getStat(current);
      if (!_canOptimize(left, right, used)) {
        used.addAll(stat.readings.keys);
        continue;
      }

      final leftVariable = left.variable;
      final rightVariable = right.variable;

      final leftDeclaration = leftVariable.declaration;
      final leftDeclarationParent = leftDeclaration.parent;
      if (leftDeclarationParent != current.parent) {
        used.addAll(stat.readings.keys);
        continue;
      }

      final rightDeclaration = rightVariable.declaration;
      final rightDeclarationParent = rightDeclaration.parent;
      final operationInsideOperationFinder = _OperationInsideOperationFinder();
      Operation lowerDeclarationParent;
      if (leftDeclarationParent == rightDeclarationParent) {
        lowerDeclarationParent = rightDeclarationParent;
      } else {
        while (true) {
          var found = operationInsideOperationFinder.find(
              leftDeclarationParent, rightDeclarationParent);
          if (found) {
            lowerDeclarationParent = rightDeclarationParent;
            break;
          }

          found = operationInsideOperationFinder.find(
              rightDeclarationParent, leftDeclarationParent);
          if (found) {
            lowerDeclarationParent = leftDeclarationParent;
          }

          break;
        }
      }

      if (lowerDeclarationParent == null ||
          lowerDeclarationParent != rightDeclarationParent) {
        used.addAll(stat.readings.keys);
        continue;
      }

      final variableUsageCollector = _VariableUsageCollector();
      final rightOperationsUsage =
          variableUsageCollector.collect(lowerDeclarationParent, rightVariable);
      var rightVariableAssignedInConditionals = false;
      for (final operation in rightOperationsUsage) {
        if (rightVariableAssignedInConditionals) {
          break;
        }

        var parent = operation.parent;
        while (true) {
          if (parent == null) {
            break;
          }

          if (parent == rightDeclarationParent) {
            break;
          }

          if (parent is ConditionalOperation || parent is LoopOperation) {
            final stat = _stats.getStat(parent);
            final writeCount = stat.getWriteCount(rightVariable);
            if (writeCount != 0) {
              rightVariableAssignedInConditionals = true;
              break;
            }
          }

          parent = parent.parent;
        }
      }

      if (rightVariableAssignedInConditionals) {
        used.add(rightVariable);
        continue;
      }

      final variableReplacer = _VariableReplacer();
      variableReplacer.replace(
          lowerDeclarationParent, rightVariable, leftVariable);
      _replaceParameter(rightDeclaration, leftVariable, stats);
      _replaceAssign(
          binary, NopOperation('${leftVariable} = ${rightVariable}'), stats);
      _analizeUsage(lowerDeclarationParent, stats);
    }
  }

  void _analizeUsage(Operation operation, VariablesStats stats) {
    final variablesUsageResolver = VariablesUsageResolver();
    variablesUsageResolver.resolve(operation, stats);
  }

  bool _canOptimize(
      VariableOperation left, VariableOperation right, Set<Variable> used) {
    if (left == null || right == null) {
      return false;
    }

    final leftVariable = left.variable;
    final rightVariable = right.variable;
    if (used.contains(rightVariable)) {
      return false;
    }

    if (rightVariable.frozen) {
      return false;
    }

    if (leftVariable.frozen) {
      return false;
    }

    return true;
  }

  void _replaceAssign(
      BinaryOperation from, Operation to, VariablesStats stats) {
    _replaceOperation(from, to, stats);
  }

  void _replaceOperation(Operation from, Operation to, VariablesStats stats) {
    final operationReplacer = OperationReplacer();
    operationReplacer.replace(from, to, stats);
  }

  void _replaceParameter(
      ParameterOperation parameter, Variable variable, VariablesStats stats) {
    final operation = parameter.operation;
    if (operation == null) {
      _replaceOperation(parameter,
          NopOperation('${parameter.type} ${parameter.variable}'), stats);
    } else {
      final assign = binOp(OperationKind.assign, varOp(variable), operation);
      _replaceOperation(parameter, assign, stats);
    }
  }
}

class _OperationInsideOperationFinder extends SimpleOperationVisitor {
  bool _found;

  Operation _what;

  bool find(Operation where, Operation what) {
    _found = false;
    _what = what;
    where.accept(this);
    return _found;
  }

  @override
  void visit(Operation node) {
    if (node == _what) {
      _found = true;
    } else {
      super.visit(node);
    }
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

class _VariableUsageCollector extends SimpleOperationVisitor {
  List<Operation> _result;

  Variable _variable;

  List<Operation> collect(Operation operation, Variable variable) {
    _result = [];
    _variable = variable;
    operation.accept(this);
    return _result;
  }

  @override
  void visitVariable(VariableOperation node) {
    if (node.variable == _variable) {
      _result.add(node.parent);
    }
  }
}
