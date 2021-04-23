part of '../../matchers.dart';

class PostfixOrderedChoiceMatcher
    extends MultipleElementsMatcher<OrderedChoiceExpression> {
  PostfixOrderedChoiceMatcher(
      OrderedChoiceExpression expression, List<Matcher> matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixOrderedChoice(this);
  }
}
