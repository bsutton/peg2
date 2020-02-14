part of '../../generators.dart';

class OperationInitializer extends SimpleOperationVisitor {
  Operation parent;

  void initialize(Operation operation) {
    operation.accept(this);
  }

  @override
  void visit(Operation node) {
    node.parent = parent;
    parent = node;
    super.visit(node);
    parent = node.parent;
  }

  @override
  void visitMethodOperation(MethodOperation node) {
    node.parent = null;
    parent = node;
    node.visitChildren(this);
  }
}
