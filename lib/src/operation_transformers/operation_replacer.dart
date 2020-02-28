part of '../../operation_transformers.dart';

class OperationReplacer extends SimpleOperationVisitor {
  Operation _from;

  Operation _to;

  void replace(Operation from, Operation to) {
    _from = from;
    _to = to;
    final parent = from.parent;
    parent.accept(this);
    final operationInitializer = OperationInitializer();
    operationInitializer.initialize(to);
  }

  @override
  void visit(Operation node) {
    throw StateError('Replacement not supported');
  }

  @override
  void visitAction(ActionOperation node) {
    _replace(node);
  }

  @override
  void visitBinary(BinaryOperation node) {
    _replace(node);
  }

  @override
  void visitBlock(BlockOperation node) {
    _replace(node);
  }

  @override
  void visitCall(CallOperation node) {
    _replace(node);
  }

  @override
  void visitList(ListOperation node) {
    _replace(node);
  }

  @override
  void visitListAccess(ListAccessOperation node) {
    _replace(node);
  }

  @override
  void visitMemberAccess(MemberAccessOperation node) {
    _replace(node);
  }

  @override
  void visitParameter(ParameterOperation node) {
    _replace(node);
  }

  @override
  void visitReturn(ReturnOperation node) {
    _replace(node);
  }

  @override
  void visitTernary(TernaryOperation node) {
    _replace(node);
  }

  @override
  void visitUnary(UnaryOperation node) {
    _replace(node);
  }

  void _replace(Operation node) {
    if (!node.replaceChild(_from, _to)) {
      throw StateError('Unable to replace operation, operation not found');
    }
  }
}
