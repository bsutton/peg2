part of '../../expressions.dart';

class TerminalExpression extends SymbolExpression {
  @override
  final ExpressionKind kind = ExpressionKind.terminal;

  TerminalExpression(String name) : super(name);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitTerminal(this);
  }
}
