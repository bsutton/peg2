part of '../../operations.dart';

abstract class OperationVisitor {
  void visitAction(ActionOperation node);

  void visitBinary(BinaryOperation node);

  void visitBlock(BlockOperation node);

  void visitBreak(BreakOperation node);

  void visitCall(CallOperation node);

  void visitComment(CommentOperation node);

  void visitConditional(ConditionalOperation node);

  void visitConstant(ConstantOperation node);

  void visitList(ListOperation node);

  void visitListAccess(ListAccessOperation node);

  void visitLoop(LoopOperation node);

  void visitMember(MemberOperation node);

  void visitMethod(MethodOperation node);

  void visitNop(NopOperation node);

  void visitParameter(ParameterOperation node);

  void visitReturn(ReturnOperation node);

  void visitUnary(UnaryOperation node);

  void visitVariable(VariableOperation node);
}
