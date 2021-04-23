part of '../../matchers.dart';

class PostfixNotPredicateMatcher
    extends PostfixPredicateMatcher<NotPredicateExpression> {
  PostfixNotPredicateMatcher(NotPredicateExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixNotPredicate(this);
  }
}
