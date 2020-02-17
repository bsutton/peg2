part of '../../expressions.dart';

class TerminalExpression extends SymbolExpression {
  TerminalExpression(String name) : super(name);

  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitTerminal(this);
  }
}
