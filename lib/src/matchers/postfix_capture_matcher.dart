part of '../../matchers.dart';

class PostfixCaptureMatcher extends SingleElementMatcher<CaptureExpression> {
  PostfixCaptureMatcher(CaptureExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitPostfixCapture(this);
  }
}
