part of '../../expressions.dart';

class TerminalExpression extends SymbolExpression {
  TerminalExpression(String name) : super(name);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitTerminal(this);
  }
}
