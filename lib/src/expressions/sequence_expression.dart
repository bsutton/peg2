part of '../../expressions.dart';

class SequenceExpression extends MultipleExpression<Expression> {
  int? actionIndex;

  String? actionSource;

  @override
  final ExpressionKind kind = ExpressionKind.sequence;

  SequenceExpression(List<Expression> expressions, this.actionSource)
      : super(expressions);

  String get separator => ' ';

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitSequence(this);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final expression = expressions[i];
      sb.write(expression);
      if (i < length - 1) {
        sb.write(' ');
      }
    }

    return sb.toString();
  }
}
