part of '../../operation_utils.dart';

class VariableAllocator {
  final _utils = OperationUtils();

  final String Function() allocate;

  VariableAllocator(this.allocate);

  Variable alloc([bool frozen = false]) {
    final name = allocate();
    return Variable(name, frozen);
  }

  Variable newVar(BlockOperation block, String type, Operation value) {
    return _utils.newVar(block, type, this, value);
  }
}
