part of '../../expressions.dart';

abstract class PrefixExpression extends SingleExpression {
  PrefixExpression(Expression expression) : super(expression);

  String get prefix;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(prefix);
    sb.write(expression);
    return sb.toString();
  }
}
