part of '../../matchers.dart';

class TerminalMatcher extends SymbolMatcher<TerminalExpression> {
  TerminalMatcher(TerminalExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitTerminal(this);
  }
}
