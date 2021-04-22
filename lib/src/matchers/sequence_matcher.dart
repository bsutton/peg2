part of '../../matchers.dart';

class SequenceMatcher extends MultipleElementsMatcher<SequenceExpression> {
  SequenceMatcher(SequenceExpression expression, List<Matcher> matchers)
      : super(expression, matchers);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitSequence(this);
  }
}
