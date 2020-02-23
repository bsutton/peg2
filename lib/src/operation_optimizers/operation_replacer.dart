part of '../../operation_optimizers.dart';

class OperationReplacer extends SimpleOperationVisitor {
  Operation _from;

  Operation _to;

  void replace(Operation from, Operation to) {
    _from = from;
    _to = to;
    final parent = from.parent;
    parent.accept(this);
    _initialize(parent);
  }

  @override
  void visit(Operation node) {
    throw StateError('Replacement not supported');
  }

  @override
  void visitAction(ActionOperation node) {
    throw UnimplementedError();
  }

  @override
  void visitBinary(BinaryOperation node) {
    if (node.left == _from) {
      node.left = _to;
    } else if (node.right == _from) {
      node.right = _to;
    } else {
      _errorUnableToReplace();
    }
  }

  @override
  void visitBlock(BlockOperation node) {
    _replaceInList(node.operations);
  }

  @override
  void visitCall(CallOperation node) {
    _replaceInList(node.arguments);
  }

  @override
  void visitListAccess(ListAccessOperation node) {
    if (node.list == _from) {
      node.list = _to;
    } else if (node.index == _from) {
      node.index = _to;
    } else {
      _errorUnableToReplace();
    }
  }

  @override
  void visitList(ListOperation node) {
    _replaceInList(node.elements);
  }

  @override
  void visitMember(MemberOperation node) {
    node.member = _replace(node.member);
  }

  @override
  void visitParameter(ParameterOperation node) {
    node.operation = _replace(node.operation);
  }

  @override
  void visitReturn(ReturnOperation node) {
    node.operation = _replace(node.operation);
  }

  @override
  void visitUnary(UnaryOperation node) {
    node.operand = _replace(node.operand);
  }

  void _errorUnableToReplace() {
    throw StateError('Unable to replace operation, operation not found');
  }

  void _initialize(Operation parent) {
    final operationInitializer = OperationInitializer();
    operationInitializer.parent = parent;
    operationInitializer.initialize(_to);
  }

  Operation _replace(Operation operation) {
    if (operation == _from) {
      return _to;
    }

    _errorUnableToReplace();
    return null;
  }

  void _replaceInList(List<Operation> operations) {
    final index = operations.indexOf(_from);
    if (index != -1) {
      operations[index] = _to;
      return;
    }

    _errorUnableToReplace();
    return;
  }
}
