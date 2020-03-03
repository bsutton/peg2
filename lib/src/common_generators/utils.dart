part of '../../common_generators.dart';

class Utils {
  static String toUnicode(int charCode) {
    var hex = charCode.toRadixString(16);
    final length = hex.length;
    if (length < 4) {
      hex = hex.padLeft(4, '0');
    }

    return '\\u$hex';
  }

  static String escape(String string) {
    if (string.isEmpty) {
      return string;
    }

    final sb = StringBuffer();
    for (var rune in string.runes) {
      switch (rune) {
        case 9:
          sb.write(r'\t');
          break;
        case 10:
          sb.write(r'\n');
          break;
        case 13:
          sb.write(r'\r');
          break;
        case 34:
          sb.write(r'\"');
          break;
        case 36:
          sb.write(r'\$');
          break;
        case 39:
          sb.write(r"\'");
          break;
        case 92:
          sb.write(r'\\');
          break;
        default:
          if (rune < 128) {
            sb.write(String.fromCharCode(rune));
          } else {
            sb.write(toUnicode(rune));
          }

          break;
      }
    }

    final result = sb.toString();
    return result;
  }

  static String listToString(List list, [String separator = ', ']) {
    final strings = <String>[];
    for (var element in list) {
      if (element is List) {
        strings.add(listToString(element));
      } else if (element is String) {
        strings.add("\'${escape(element)}\'");
      } else {
        strings.add(element.toString());
      }
    }

    return '[${strings.join(separator)}]';
  }
}
