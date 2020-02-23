part of '../../expressions.dart';

class CaptureExpression extends SingleExpression {
  CaptureExpression(Expression expression) : super(expression);

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitCapture(this);
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
