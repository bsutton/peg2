part of '../../operation_optimizers.dart';

class VariableUsageResolver extends SimpleOperationVisitor {
  void resolve(Operation operation) {
    operation.accept(this);
  }

  @override
  void visitBinary(BinaryOperation node) {
    super.visitBinary(node);
    switch (node.kind) {
      case OperationKind.assign:
        if (node.left is VariableOperation) {
          final left = node.left as VariableOperation;
          final variable = left.variable;
          final variablesUsage = node.variablesUsage;
          variablesUsage.addReadCount(variable, -1);
          variablesUsage.addReadCount(variable, 1);
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
