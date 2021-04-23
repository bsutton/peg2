part of '../../matchers.dart';

class PostfixOptionalMatcher extends SingleElementMatcher<OptionalExpression> {
  PostfixOptionalMatcher(OptionalExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixOptional(this);
  }
}
