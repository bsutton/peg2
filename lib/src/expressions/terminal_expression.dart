part of '../../expressions.dart';

class TerminalExpression extends SymbolExpression {
  TerminalExpression(String name) : super(name);

  @override
  ExpressionKind get kind => ExpressionKind.terminal;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitTerminal(this);
  }
}
