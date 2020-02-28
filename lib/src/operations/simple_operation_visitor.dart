part of '../../operations.dart';

class SimpleOperationVisitor extends OperationVisitor {
  void visit(Operation node) {
    node.visitChildren(this);
  }

  @override
  void visitAction(ActionOperation node) => visit(node);

  @override
  void visitBinary(BinaryOperation node) => visit(node);

  @override
  void visitBlock(BlockOperation node) => visit(node);

  @override
  void visitBreak(BreakOperation node) => visit(node);

  @override
  void visitCall(CallOperation node) => visit(node);

  @override
  void visitComment(CommentOperation node) => visit(node);

  @override
  void visitConditional(ConditionalOperation node) => visit(node);

  @override
  void visitConstant(ConstantOperation node) => visit(node);

  @override
  void visitList(ListOperation node) => visit(node);

  @override
  void visitListAccess(ListAccessOperation node) => visit(node);

  @override
  void visitLoop(LoopOperation node) => visit(node);

  @override
  void visitMemberAccess(MemberAccessOperation node) => visit(node);

  @override
  void visitMethod(MethodOperation node) => visit(node);

  @override
  void visitNop(NopOperation node) => visit(node);

  @override
  void visitParameter(ParameterOperation node) => visit(node);

  @override
  void visitReturn(ReturnOperation node) => visit(node);

  @override
  void visitTernary(TernaryOperation node) => visit(node);

  @override
  void visitUnary(UnaryOperation node) => visit(node);

  @override
  void visitVariable(VariableOperation node) => visit(node);
}
