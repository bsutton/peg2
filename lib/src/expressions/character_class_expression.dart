part of '../../expressions.dart';

class CharacterClassExpression extends Expression {
  final SparseBoolList ranges = SparseBoolList();

  @override
  final ExpressionKind kind = ExpressionKind.characterClass;

  CharacterClassExpression(List<List<int>> ranges) {
    if (ranges.isEmpty) {
      throw ArgumentError('List of ranges should not be empty');
    }

    for (final range in ranges) {
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

      final group = GroupedRangeList(start, end, true);
      this.ranges.addGroup(group);
    }

    this.ranges.freeze();
  }

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitCharacterClass(this);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('[');
    for (var group in ranges.groups) {
      if (group.start == group.end) {
        sb.write(_escape(group.start));
      } else {
        sb.write(_escape(group.start));
        sb.write('-');
        sb.write(_escape(group.end));
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
      case 92:
        return '\\\\';
      case 93:
        return '\\]';
    }

    return String.fromCharCode(character);
  }
}
