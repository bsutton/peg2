part of '../../matchers.dart';

class ZeroOrMoreMatcher extends SingleElementMatcher<ZeroOrMoreExpression> {
  ZeroOrMoreMatcher(ZeroOrMoreExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitZeroOrMore(this);
  }
}
