part of '../../matchers.dart';

abstract class Matcher<E extends Expression> {
  E expression;

  Matcher(this.expression);

  String get resultType => expression.resultType;

  bool get resultUsed => expression.resultUsed;

  T accept<T>(MatcherVisitor<T> visitor);

  void visitChildren<T>(MatcherVisitor<T> visitor) {
    return;
  }
}
