part of '../../expressions.dart';

class SubterminalExpression extends SymbolExpression {
  SubterminalExpression(String name) : super(name);

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitSubterminal(this);
  }
}
