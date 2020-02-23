part of '../../operation_optimizers.dart';

class UnusedVariablesRemover extends SimpleOperationVisitor {
  void remove(Operation operation) {
    operation.accept(this);
  }

  @override
  void visitParameter(ParameterOperation node) {
    super.visitParameter(node);
    final parent = node.parent;
    final variable = node.variable;
    var reads = parent.readings[variable];
    var writes = parent.writings[variable];
    reads ??= 0;
    writes ??= 0;
    if (reads == 0 && writes == 0) {
      final operationReplacer = OperationReplacer();
      if (node.operation == null) {
        if (parent is BlockOperation) {
          operationReplacer.replace(node, NopOperation());
        }
      } else {
        switch (node.operation.kind) {
          case OperationKind.call:
            final operationReplacer = OperationReplacer();
            operationReplacer.replace(node, node.operation);
            break;
          default:
            break;
        }
      }
    }
  }
}
