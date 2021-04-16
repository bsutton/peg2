part of '../../expressions.dart';

class OrderedChoiceExpression extends MultipleExpression<SequenceExpression> {
  @override
  final ExpressionKind kind = ExpressionKind.orderedChoice;

  OrderedChoiceExpression(List<SequenceExpression> expressions)
      : super(expressions);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitOrderedChoice(this);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    final enclose = parent != null;
    if (enclose) {
      sb.write('(');
    }

    final list = <Expression>[];
    for (var expression in expressions) {
      list.add(expression);
    }

    sb.write(list.join(' / '));
    if (enclose) {
      sb.write(')');
    }

    return sb.toString();
  }
}
