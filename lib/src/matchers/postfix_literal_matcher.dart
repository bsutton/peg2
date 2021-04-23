part of '../../matchers.dart';

class PostfixLiteralMatcher extends Matcher<LiteralExpression> {
  PostfixLiteralMatcher(LiteralExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixLiteral(this);
  }
}
