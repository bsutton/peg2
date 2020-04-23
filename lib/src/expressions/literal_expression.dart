part of '../../expressions.dart';

class LiteralExpression extends Expression {
  final String text;

  LiteralExpression(this.text) {
    if (text == null) {
      throw ArgumentError.notNull('text');
    }
  }

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitLiteral(this);
  }

  @override
  String toString() {
    final quote = '"';
    final quoteChar = quote.codeUnitAt(0);
    final sb = StringBuffer();
    sb.write(quote);
    for (var rune in text.runes) {
      sb.write(_escape(rune, quoteChar));
    }

    sb.write(quote);
    return sb.toString();
  }

  String _escape(int character, int quote) {
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
      case 92:
        return '\\\\';
    }

    if (character == quote) {
      return '\\${String.fromCharCode(character)}';
    }

    return String.fromCharCode(character);
  }
}
