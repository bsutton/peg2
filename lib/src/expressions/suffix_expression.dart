part of '../../expressions.dart';

abstract class SuffixExpression extends SingleExpression {
  SuffixExpression(Expression expression) : super(expression);

  String get suffix;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(expression);
    sb.write(suffix);
    return sb.toString();
  }
}
