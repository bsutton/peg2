part of '../../matchers.dart';

class OneOrMoreMatcher extends SingleElementMatcher<OneOrMoreExpression> {
  OneOrMoreMatcher(OneOrMoreExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitOneOrMore(this);
  }
}
