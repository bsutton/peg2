part of '../../operation_utils.dart';

class VariableAllocator {
  final _utils = OperationUtils();

  final String Function() allocName;

  VariableAllocator(this.allocName);

  Variable alloc([bool frozen = false]) {
    final name = allocName();
    return Variable(name, frozen);
  }

  Variable newVar(BlockOperation block, String type, Operation value) {
    return _utils.newVar(block, type, this, value);
  }
}
