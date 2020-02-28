part of '../../operation_optimizers.dart';

class UnusedVariablesRemover extends SimpleOperationVisitor
    with OperationUtils {
  List<ParameterOperation> _paramaters;

  VariablesStats _stats;

  void remove(Operation operation, VariablesStats stats) {
    _paramaters = [];
    _stats = stats;
    operation.accept(this);
    for (final paramater in _paramaters) {
      _replaceParameter(paramater);
    }
  }

  @override
  void visitBinary(BinaryOperation node) {
    if (node.kind != OperationKind.assign) {
      return;
    }

    final left = getOp<VariableOperation>(node.left);
    if (left == null) {
      return;
    }

    final leftVariable = left.variable;
    if (leftVariable.frozen) {
      return;
    }

    final leftVarStat = _stats.getVarDeclStat(leftVariable);
    if (leftVarStat == null) {
      return;
    }

    final readCount = leftVarStat.getReadCount(leftVariable);
    if (readCount != 0) {
      return;
    }

    final right = node.right;
    switch (right.kind) {
      case OperationKind.constant:
      case OperationKind.list:
      case OperationKind.variable:
        _replaceOperation(node, NopOperation());
        break;
      default:
        _replaceOperation(node, right);
        break;
    }
  }

  void _replaceParameter(ParameterOperation node) {
    final operationReplacer = OperationReplacer();
    final operation = node.operation;
    if (operation == null) {
      operationReplacer.replace(node, NopOperation());
    } else {
      switch (operation.kind) {
        case OperationKind.constant:
        case OperationKind.variable:
          _replaceOperation(node, NopOperation());
          break;
        default:
          operationReplacer.replace(node, node.operation);
          break;
      }
    }
  }

  @override
  void visitParameter(ParameterOperation node) {
    final variable = node.variable;
    if (variable.frozen) {
      return;
    }

    final stat = _stats.getVarDeclStat(variable);
    if (stat == null) {
      return;
    }

    final readCount = stat.getReadCount(variable);
    if (readCount == 0) {
      _paramaters.add(node);
    }
  }

  void _replaceOperation(Operation from, Operation to) {
    final operationReplacer = OperationReplacer();
    operationReplacer.replace(from, to);
  }
}
