part of '../../operations.dart';

abstract class OperationVisitor {
  void visitActionOperation(ActionOperation node);

  void visitBinaryOperation(BinaryOperation node);

  void visitBlockOperation(BlockOperation node);

  void visitBreakOperation(BreakOperation node);

  void visitCallOperation(CallOperation node);

  void visitConditionalOperation(ConditionalOperation node);

  void visitConstantOperation(ConstantOperation node);

  void visitListAccessOperation(ListAccessOperation node);

  void visitListOperation(ListOperation node);

  void visitLoopOperation(LoopOperation node);

  void visitMemberOperation(MemberOperation node);

  void visitMethodOperation(MethodOperation node);

  void visitNopOperation(NopOperation node);

  void visitParameterOperation(ParameterOperation node);

  void visitReturnOperation(ReturnOperation node);

  void visitUnaryOperation(UnaryOperation node);

  void visitVariableOperation(VariableOperation node);
}
