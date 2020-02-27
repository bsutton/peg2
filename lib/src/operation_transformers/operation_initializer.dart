part of '../../operation_transformers.dart';

class OperationInitializer extends SimpleOperationVisitor {
  Operation _parent;

  void initialize(Operation operation) {
    _parent = operation;
    operation.visitChildren(this);
  }

  @override
  void visit(Operation node) {
    node.parent = _parent;
    _parent = node;
    super.visit(node);
    _parent = node.parent;
  }

  @override
  void visitMethod(MethodOperation node) {
    node.parent = null;
    final parent = _parent;
    _parent = node;
    node.visitChildren(this);
    _parent = parent;
  }
}
