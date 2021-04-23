part of '../../matchers.dart';

class PostfixCharacterClassMatcher extends Matcher<CharacterClassExpression> {
  final SparseBoolList inputCharacters;

  PostfixCharacterClassMatcher(
      CharacterClassExpression expression, this.inputCharacters)
      : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixCharacterClass(this);
  }
}
