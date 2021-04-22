part of '../../matchers.dart';

class SubterminalMatcher extends SymbolMatcher<SubterminalExpression> {
  SubterminalMatcher(SubterminalExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitSubterminal(this);
  }
}
