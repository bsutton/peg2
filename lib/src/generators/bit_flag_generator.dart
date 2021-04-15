// @dart = 2.10
part of '../../generators.dart';

class BitFlagGenerator {
  static const int size = 32;

  final int length;

  final String name;

  final List<String> variables = [];

  BitFlagGenerator(this.length, this.name) {
    if (length < 1) {
      throw ArgumentError.value(length, 'length', 'Must be greater than 0');
    }

    var count = length ~/ size;
    count = length * size == count ? count : count + 1;
    for (var i = 0; i < count; i++) {
      variables.add('$name$i');
    }
  }

  List<String> generateClear() {
    final code = <String>[];
    for (final variable in variables) {
      final sink = StringBuffer();
      sink.write(variable);
      sink.write(' = 0;');
      code.add(sink.toString());
    }

    return code;
  }

  List<String> generateSet(bool set, List<int> bits) {
    final code = <String>[];
    final mask = pow(2, size).round() - 1;
    final init = set ? 0 : mask;
    final values = List<int>.filled(variables.length, null);
    for (var i = 0; i < bits.length; i++) {
      final bit = bits[i];
      RangeError.checkValueInInterval(bit, 0, length - 1, 'bit');
      final index = getIndex(bit);
      final position = getPosition(bit);
      var value = values[index];
      if (value == null) {
        value = init;
        values[index] = value;
      }

      value = 1 << position;
      if (set) {
        values[index] |= value;
      } else {
        values[index] &= (~value) & mask;
      }
    }

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        continue;
      }

      final sink = StringBuffer();
      final hexValue = '0x' + value.toRadixString(16);
      final variable = variables[i];
      sink.write(variable);
      if (set) {
        sink.write(' |= ');
      } else {
        sink.write(' &= ');
      }

      sink.write(hexValue);
      sink.write(';');
      code.add(sink.toString());
    }

    return code;
  }

  int getIndex(int bit) {
    return bit ~/ size;
  }

  int getPosition(int bit) {
    if (bit <= size - 1) {
      return bit;
    }

    return bit % size;
  }
}
