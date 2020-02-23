part of '../../operation_optimizers.dart';

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
  void visitBinary(BinaryOperation node) {
    super.visitBinary(node);
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
  void visitConditional(ConditionalOperation node) {
    _result = {};
    super.visitConditional(node);
    _removeResults(node);
  }

  @override
  void visitLoop(LoopOperation node) {
    _result = {};
    super.visitLoop(node);
    _removeResults(node);
  }

  @override
  void visitParameter(ParameterOperation node) {
    super.visitParameter(node);
    _result[node.variable] = node.operation;
    node.variableResults = {..._result};
  }

  @override
  void visitVariable(VariableOperation node) {
    super.visitVariable(node);
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
