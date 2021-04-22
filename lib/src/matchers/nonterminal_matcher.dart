part of '../../matchers.dart';

class NonterminalMatcher extends SymbolMatcher<NonterminalExpression> {
  NonterminalMatcher(NonterminalExpression expression) : super(expression);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitNonterminal(this);
  }
}
