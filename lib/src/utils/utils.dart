part of '../../utils.dart';

class Utils {
  static String escapeString(String text, [bool quote = true]) {
    text = text.replaceAll('\\', r'\\');
    text = text.replaceAll('\b', r'\b');
    text = text.replaceAll('\f', r'\f');
    text = text.replaceAll('\n', r'\n');
    text = text.replaceAll('\r', r'\r');
    text = text.replaceAll('\t', r'\t');
    text = text.replaceAll('\v', r'\v');
    text = text.replaceAll('\'', '\\\'');
    text = text.replaceAll('\$', r'\$');
    if (!quote) {
      return text;
    }

    return '\'$text\'';
  }

  static String expr2Str(Expression expression) {
    return '${expression.runtimeType.toString().substring(0, 3)}${expression.id}: ${escapeString(expression.toString())}';
  }

  static String getNullableType(String? type) {
    if (type == null) {
      return 'dynamic';
    }

    type = type.trim();
    if (isDynamicType(type)) {
      return type;
    }

    if (type.endsWith('?')) {
      return type;
    }

    return '$type?';
  }

  static String getNullCheckedValue(String value, [String? type]) {
    type ??= 'dynamic';
    if (isNullableType(type)) {
      return value;
    }

    return '$value!';
  }

  static bool isDynamicType(String type) {
    type = type.trim();
    if (type == 'dynamic' || type == 'dynamic?') {
      return true;
    }

    return false;
  }

  static bool isNullableType(String type) {
    type = type.trim();
    if (type == 'dynamic' || type == 'dynamic?') {
      return true;
    }

    return type.endsWith('?');
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
