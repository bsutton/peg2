part of '../../matchers.dart';

class PostfixAndPredicateMatcher
    extends PostfixPredicateMatcher<AndPredicateExpression> {
  PostfixAndPredicateMatcher(AndPredicateExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixAndPredicate(this);
  }
}
