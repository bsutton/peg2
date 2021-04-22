part of '../../matchers.dart';

class NotPredicateMatcher extends PredicateMatcher<NotPredicateExpression> {
  NotPredicateMatcher(NotPredicateExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitNotPredicate(this);
  }
}
