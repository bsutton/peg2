part of '../../matchers.dart';

class PostfixTerminalMatcher extends PostfixSymbolMatcher<TerminalExpression> {
  PostfixTerminalMatcher(TerminalExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixTerminal(this);
  }
}
