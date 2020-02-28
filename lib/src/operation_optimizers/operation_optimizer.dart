part of '../../operation_optimizers.dart';

class OperationOptimizer {
  void optimize(BlockOperation operation) {
    final variableUsageResolver = VariableUsageResolver();
    variableUsageResolver.resolve(operation);

    final conditionalOperationOptimizer = ConditionalOperationOptimizer();
    conditionalOperationOptimizer.optimize(operation);

    //final variableUsageOptimizer = VariableUsageOptimizer();
    //variableUsageOptimizer.optimize(operation);

    final unusedVariablesRemover = UnusedVariablesRemover();
    unusedVariablesRemover.remove(operation);
  }
}
