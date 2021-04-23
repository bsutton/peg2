part of '../../matchers.dart';

class PostfixSubterminalMatcher
    extends PostfixSymbolMatcher<SubterminalExpression> {
  PostfixSubterminalMatcher(SubterminalExpression expression)
      : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixSubterminal(this);
  }
}
