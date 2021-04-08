part of '../../expressions.dart';

class SequenceExpression extends MultipleExpression<Expression> {
  SequenceExpression(List<Expression> expressions, this.actionSource)
      : super(expressions);

  int? actionIndex;

  String? actionSource;

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
