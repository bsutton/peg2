part of '../../matchers.dart';

class AndPredicateMatcher extends PredicateMatcher<AndPredicateExpression> {
  AndPredicateMatcher(AndPredicateExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitAndPredicate(this);
  }
}
