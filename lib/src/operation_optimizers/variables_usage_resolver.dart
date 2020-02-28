part of '../../operation_optimizers.dart';

class VariablesUsageResolver extends SimpleOperationVisitor
    with OperationUtils {
  VariablesStats _stats;

  VariablesStats resolve(Operation operation, VariablesStats stats) {
    _stats = stats;
    operation.accept(this);
    return _stats;
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
          final stat = _stats.getStat(node);
          stat.addReadCount(variable, -1);
        }

        break;
      default:
        break;
    }
  }

  @override
  void visitMemberAccess(MemberAccessOperation node) {
    super.visitMemberAccess(node);
    final member = getOp<VariableOperation>(node.member);
    if (member != null) {
      final variable = member.variable;
      final stat = _stats.getStat(node);
      stat.addReadCount(variable, -1);
    }
  }

  @override
  void visitVariable(VariableOperation node) {
    super.visitVariable(node);
    final variable = node.variable;
    final stat = _stats.getStat(node);
    stat.addReadCount(variable, 1);
  }
}
