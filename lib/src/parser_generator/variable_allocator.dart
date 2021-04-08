// @dart = 2.10
part of '../../parser_generator.dart';

class VariableAllocator {
  final String prefix;

  VariableAllocator(this.prefix);

  int _index = 0;

  String alloc() {
    final result = '$prefix${_index++}';
    return result;
  }
}
