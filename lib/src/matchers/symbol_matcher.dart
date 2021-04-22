part of '../../matchers.dart';

abstract class SymbolMatcher<E extends SymbolExpression> extends Matcher<E> {
  SymbolMatcher(E expression) : super(expression);
}
