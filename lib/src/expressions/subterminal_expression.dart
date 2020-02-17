part of '../../expressions.dart';

class SubterminalExpression extends SymbolExpression {
  SubterminalExpression(String name) : super(name);

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitSubterminal(this);
  }
}
