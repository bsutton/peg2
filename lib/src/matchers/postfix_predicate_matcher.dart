part of '../../matchers.dart';

abstract class PostfixPredicateMatcher<E extends PrefixExpression>
    extends SingleElementMatcher<E> {
  PostfixPredicateMatcher(E expression, Matcher matcher)
      : super(expression, matcher);
}
