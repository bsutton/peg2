part of '../../utils.dart';

class VariableAllocator {
  final String prefix;

  VariableAllocator(this.prefix);

  int _index = 0;

  String alloc() {
    final result = '$prefix${_index++}';
    return result;
  }
}
