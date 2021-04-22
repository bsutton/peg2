part of '../../matchers.dart';

abstract class SingleElementMatcher<E extends Expression> extends Matcher<E> {
  final Matcher matcher;

  SingleElementMatcher(E expression, this.matcher) : super(expression);

  @override
  void visitChildren<T>(MatcherVisitor<T> visitor) {
    matcher.accept(visitor);
  }
}
