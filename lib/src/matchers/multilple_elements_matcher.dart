part of '../../matchers.dart';

abstract class MultipleElementsMatcher<E extends Expression>
    extends Matcher<E> {
  final List<Matcher> matchers;

  MultipleElementsMatcher(E expression, this.matchers) : super(expression);

  @override
  void visitChildren<T>(MatcherVisitor<T> visitor) {
    for (final matcher in matchers) {
      matcher.accept(visitor);
    }
  }
}
