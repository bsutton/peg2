class VariableAllocator {
  final String prefix;

  VariableAllocator(this.prefix);

  int _index = 0;

  String allocate() {
    final result = '$prefix${_index++}';
    return result;
  }
}
