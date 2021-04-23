part of '../../matchers.dart';

class PostfixNonterminalMatcher
    extends PostfixSymbolMatcher<NonterminalExpression> {
  PostfixNonterminalMatcher(NonterminalExpression expression)
      : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixNonterminal(this);
  }
}
