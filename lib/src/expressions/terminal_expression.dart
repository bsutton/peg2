part of '../../expressions.dart';

class TerminalExpression extends SymbolExpression {
  TerminalExpression(String name) : super(name);

  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitTerminal(this);
  }
}
