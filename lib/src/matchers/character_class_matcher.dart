part of '../../matchers.dart';

class CharacterClassMatcher extends Matcher<CharacterClassExpression> {
  CharacterClassMatcher(CharacterClassExpression expression)
      : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitCharacterClass(this);
  }
}
