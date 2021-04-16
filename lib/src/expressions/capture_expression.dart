part of '../../expressions.dart';

class CaptureExpression extends SingleExpression {
  @override
  final ExpressionKind kind = ExpressionKind.capture;

  CaptureExpression(Expression expression) : super(expression);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitCapture(this);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('<');
    sb.write(expression);
    sb.write('>');
    return sb.toString();
  }
}
