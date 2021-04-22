part of '../../matchers.dart';

class OrderedChoiceMatcher
    extends MultipleElementsMatcher<OrderedChoiceExpression> {
  OrderedChoiceMatcher(
      OrderedChoiceExpression expression, List<Matcher> matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitOrderedChoice(this);
  }
}
