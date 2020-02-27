part of '../../operation_optimizers.dart';

class UnusedVariablesRemover extends SimpleOperationVisitor {
  void remove(Operation operation) {
    operation.accept(this);
  }

  @override
  void visitParameter(ParameterOperation node) {
    if (node.frozen) {
      return;
    }

    final parent = node.parent;
    final variable = node.variable;
    final variablesUsage = parent.variablesUsage;
    final readCount = variablesUsage.getReadCount(variable);
    final writeCount = variablesUsage.getWriteCount(variable);
    if (readCount == 0 && writeCount == 0) {
      if (parent is BlockOperation) {
        final operationReplacer = OperationReplacer();
        final operation = node.operation;
        if (operation == null) {
          if (parent is BlockOperation) {
            operationReplacer.replace(node, NopOperation());
          }
        } else {
          switch (operation.kind) {
            case OperationKind.call:
              final operationReplacer = OperationReplacer();
              operationReplacer.replace(node, node.operation);
              break;
            case OperationKind.constant:
            case OperationKind.variable:
              final operationReplacer = OperationReplacer();
              operationReplacer.replace(node, NopOperation());
              break;
            default:
              break;
          }
        }
      }
    }
  }
}
