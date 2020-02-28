part of '../../operation_optimizers.dart';

class VariablesUsageResolver extends SimpleOperationVisitor
    with OperationUtils {
  void resolve(Operation operation) {
    operation.accept(this);
  }

  @override
  void visitBinary(BinaryOperation node) {
    super.visitBinary(node);
    switch (node.kind) {
      case OperationKind.assign:
      case OperationKind.addAssign:
        final left = getOp<VariableOperation>(node.left);
        if (left != null) {
          final variable = left.variable;
          final variablesUsage = node.variablesUsage;
          variablesUsage.addReadCount(variable, -1);
        }

        break;
      default:
        break;
    }
  }

  @override
  void visitVariable(VariableOperation node) {
    super.visitVariable(node);
    final variable = node.variable;
    final variablesUsage = node.variablesUsage;
    variablesUsage.addReadCount(variable, 1);
  }
}
