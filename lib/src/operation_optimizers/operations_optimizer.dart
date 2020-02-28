part of '../../operation_optimizers.dart';

class OperationsOptimizer {
  void optimize(BlockOperation operation) {
    _resolveVariablesUsage(operation);
    final conditionalOperationOptimizer = ConditionalOperationOptimizer();
    conditionalOperationOptimizer.optimize(operation);

    _resolveVariablesUsage(operation);
    final variableUsageOptimizer = VariableUsageOptimizer();
    variableUsageOptimizer.optimize(operation);

    _resolveVariablesUsage(operation);
    //final unusedVariablesRemover = UnusedVariablesRemover();
    //unusedVariablesRemover.remove(operation);
  }

  void _resolveVariablesUsage(Operation operation) {
    final variableUsageResolver = VariablesUsageResolver();
    variableUsageResolver.resolve(operation);
  }
}
