part of '../../utils.dart';

class Utils {
  static String expr2Str(Expression expression) {
    return '${expression.runtimeType.toString().substring(0, 3)}${expression.id}: ${expression}';
  }

  static String range2Str(RangeList range) {
    String escape(int char) {
      if (char >= 32 && char <= 127) {
        return String.fromCharCode(char);
      } else {
        return char.toString();
      }
    }

    final start = range.start;
    final end = range.end;
    if (start == end) {
      return '[${escape(start)}]';
    } else {
      return '[${escape(start)}-${escape(end)}]';
    }
  }
}
