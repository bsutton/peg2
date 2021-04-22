part of '../../matchers.dart';

abstract class PredicateMatcher<E extends PrefixExpression>
    extends SingleElementMatcher<E> {
  PredicateMatcher(E expression, Matcher matcher) : super(expression, matcher);
}
