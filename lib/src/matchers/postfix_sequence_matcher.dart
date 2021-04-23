part of '../../matchers.dart';

class PostfixSequenceMatcher
    extends MultipleElementsMatcher<SequenceExpression> {
  PostfixSequenceMatcher(SequenceExpression expression, List<Matcher> matchers)
      : super(expression, matchers);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixSequence(this);
  }
}
