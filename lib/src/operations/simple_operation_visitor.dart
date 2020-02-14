part of '../../operations.dart';

abstract class SimpleOperationVisitor extends OperationVisitor {
  void visit(Operation node) {
    node.visitChildren(this);
  }

  @override
  void visitActionOperation(ActionOperation node) => visit(node);

  @override
  void visitBinaryOperation(BinaryOperation node) => visit(node);

  @override
  void visitBlockOperation(BlockOperation node) => visit(node);

  @override
  void visitBreakOperation(BreakOperation node) => visit(node);

  @override
  void visitCallOperation(CallOperation node) => visit(node);

  @override
  void visitConditionalOperation(ConditionalOperation node) => visit(node);

  @override
  void visitConstantOperation(ConstantOperation node) => visit(node);

  @override
  void visitListOperation(ListOperation node) => visit(node);

  @override
  void visitLoopOperation(LoopOperation node) => visit(node);

  @override
  void visitMemberOperation(MemberOperation node) => visit(node);

  @override
  void visitMethodOperation(MethodOperation node) => visit(node);

  @override
  void visitNopOperation(NopOperation node) => visit(node);

  @override
  void visitParameterOperation(ParameterOperation node) => visit(node);

  @override
  void visitReturnOperation(ReturnOperation node) => visit(node);

  @override
  void visitUnaryOperation(UnaryOperation node) => visit(node);

  @override
  void visitVariableOperation(VariableOperation node) => visit(node);
}
