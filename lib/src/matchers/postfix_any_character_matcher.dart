part of '../../matchers.dart';

class PostfixAnyCharacterMatcher extends Matcher<AnyCharacterExpression> {
  PostfixAnyCharacterMatcher(AnyCharacterExpression expression)
      : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixAnyCharacter(this);
  }
}
