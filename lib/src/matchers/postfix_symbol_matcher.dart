part of '../../matchers.dart';

abstract class PostfixSymbolMatcher<E extends SymbolExpression>
    extends Matcher<E> {
  PostfixSymbolMatcher(E expression) : super(expression);
}
