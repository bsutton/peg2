part of '../../matchers.dart';

class AnyCharacterMatcher extends Matcher<AnyCharacterExpression> {
  AnyCharacterMatcher(AnyCharacterExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitAnyCharacter(this);
  }
}
