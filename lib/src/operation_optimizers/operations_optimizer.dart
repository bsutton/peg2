part of '../../operation_optimizers.dart';

class OperationsOptimizer {
  void optimize(BlockOperation operation) {
    var stats = _resolveVariablesUsage(operation);
    final variableUsageOptimizer = VariableUsageOptimizer();
    variableUsageOptimizer.optimize(operation, stats);

    stats = _resolveVariablesUsage(operation);
    final unusedVariablesRemover = UnusedVariablesRemover();
    unusedVariablesRemover.remove(operation, stats);

    stats = _resolveVariablesUsage(operation);
    final conditionalOperationOptimizer = ConditionalOperationOptimizer();
    conditionalOperationOptimizer.optimize(operation, stats);
  }

  VariablesStats _resolveVariablesUsage(Operation operation) {
    final variableUsageResolver = VariablesUsageResolver();
    return variableUsageResolver.resolve(operation, VariablesStats());
  }
}
