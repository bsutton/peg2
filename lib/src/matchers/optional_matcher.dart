part of '../../matchers.dart';

class OptionalMatcher extends SingleElementMatcher<OptionalExpression> {
  OptionalMatcher(OptionalExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitOptional(this);
  }
}
