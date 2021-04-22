part of '../../matchers.dart';

class LiteralMatcher extends Matcher<LiteralExpression> {
  LiteralMatcher(LiteralExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitLiteral(this);
  }
}
