part of '../../matchers.dart';

class CaptureMatcher extends SingleElementMatcher<CaptureExpression> {
  CaptureMatcher(CaptureExpression expression, Matcher matcher)
      : super(expression, matcher);

  @override
  T accept<T>(MatcherVisitor<T> visitor) {
    return visitor.visitCapture(this);
  }
}
