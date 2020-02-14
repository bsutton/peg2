part of '../../expressions.dart';

class CharacterClassExpression extends Expression {
  List<List<int>> ranges;

  CharacterClassExpression(List<List<int>> ranges) {
    if (ranges == null) {
      throw ArgumentError.notNull('ranges');
    }

    if (ranges.isEmpty) {
      throw ArgumentError('List of ranges should not be empty');
    }

    int max(int x, int y) => x > y ? x : y;
    int min(int x, int y) => x < y ? x : y;
    final data = <List<int>>[];
    for (var range in ranges) {
      if (range.length != 2) {
        throw ArgumentError('ranges');
      }

      final start = range[0];
      final end = range[1];
      if (start is! int) {
        throw ArgumentError('ranges');
      }

      if (end is! int) {
        throw ArgumentError('ranges');
      }

      if (start > end) {
        throw ArgumentError('ranges');
      }

      if (start > 0x10ffff) {
        throw RangeError.value(start, 'start');
      }

      if (end > 0x10ffff) {
        throw RangeError.value(start, 'end');
      }

      data.add([start, end]);
    }

    data.sort((a, b) => a[0].compareTo(b[0]));
    for (var i = 0; i < data.length; i++) {
      if (i < data.length - 1) {
        final prev = data[i];
        final next = data[i + 1];
        final p0 = prev[0];
        final p1 = prev[1];
        final n0 = next[0];
        final n1 = next[1];
        if (p1 >= n0 || p1 + 1 == n0) {
          data[i] = [min(p0, n0), max(p1, n1)];
          data.removeAt(i + 1);
          i--;
        }
      }
    }

    this.ranges = data;
  }

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitCharacterClass(this);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('[');
    for (var range in ranges) {
      if (range[0] == range[1]) {
        sb.write(_escape(range[0]));
      } else {
        sb.write(_escape(range[0]));
        sb.write('-');
        sb.write(_escape(range[1]));
      }
    }

    sb.write(']');
    return sb.toString();
  }

  String _escape(int character) {
    switch (character) {
      case 9:
        return '\\t';
      case 10:
        return '\\n';
      case 13:
        return '\\r';
    }

    if (character < 32 || character >= 127) {
      return '\\u${character.toRadixString(16)}';
    }

    switch (character) {
      case 45:
        return '\\-';
      case 91:
        return '\\[';
      case 92:
        return '\\\\';
      case 93:
        return '\\]';
    }

    return String.fromCharCode(character);
  }
}
