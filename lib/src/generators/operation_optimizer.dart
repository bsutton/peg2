part of '../../generators.dart';

class OperationOptimizer {
  void optimize(BlockOperation operation) {
    final lastAssignedResultResolver = LastAssignedResultResolver();
    operation.accept(lastAssignedResultResolver);
    final unusedVariablesRemover = UnusedVariablesRemover();
    unusedVariablesRemover.remove(operation);
  }
}
