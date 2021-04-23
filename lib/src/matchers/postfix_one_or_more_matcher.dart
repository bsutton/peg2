part of '../../matchers.dart';

class PostfixOneOrMoreMatcher
    extends SingleElementMatcher<OneOrMoreExpression> {
  PostfixOneOrMoreMatcher(OneOrMoreExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixOneOrMore(this);
  }
}
