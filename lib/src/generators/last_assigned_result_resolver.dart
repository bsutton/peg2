part of '../../generators.dart';

class LastAssignedResultResolver extends SimpleOperationVisitor {
  Map<Variable, Operation> _result = {};

  void resolve(Operation operation) {
    operation.accept(this);
  }

  @override
  void visit(Operation node) {
    super.visit(node);
    node.variableResults = {..._result};
  }

  @override
  void visitBinaryOperation(BinaryOperation node) {
    super.visitBinaryOperation(node);
    if (node.kind == OperationKind.assign) {
      if (node.left is VariableOperation) {
        final left = node.left as VariableOperation;
        final variable = left.variable;
        _result[variable] = node.right;
        node.parent.variableUsage(variable, -1, VariableUsage.read);
        node.parent.variableUsage(variable, 1, VariableUsage.write);
      }
    }

    node.variableResults = {..._result};
  }

  @override
  void visitConditionalOperation(ConditionalOperation node) {
    _result = {};
    super.visitConditionalOperation(node);
    _removeResults(node);
  }

  @override
  void visitLoopOperation(LoopOperation node) {
    _result = {};
    super.visitLoopOperation(node);
    _removeResults(node);
  }

  @override
  void visitParameterOperation(ParameterOperation node) {
    super.visitParameterOperation(node);
    _result[node.variable] = node.operation;
    node.variableResults = {..._result};
  }

  @override
  void visitVariableOperation(VariableOperation node) {
    super.visitVariableOperation(node);
    final variable = node.variable;
    node.parent.variableUsage(variable, 1, VariableUsage.read);
  }

  void _removeResults(Operation node) {
    final writings = node.writings;
    final variableResults = node.variableResults;
    for (final variable in writings.keys) {
      final count = writings[variable];
      if (count > 0) {
        variableResults.remove(variable);
      }
    }
  }
}
