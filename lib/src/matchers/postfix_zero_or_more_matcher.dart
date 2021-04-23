part of '../../matchers.dart';

class PostfixZeroOrMoreMatcher
    extends SingleElementMatcher<ZeroOrMoreExpression> {
  PostfixZeroOrMoreMatcher(ZeroOrMoreExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixZeroOrMore(this);
  }
}
