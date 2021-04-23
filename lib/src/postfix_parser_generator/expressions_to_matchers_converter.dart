part of '../../postfix_parser_generator.dart';

class ExpressionsToMatchersConverter extends ExpressionVisitor<List<Matcher>> {
  bool entryPoint = false;

  SparseBoolList inputCharacters = SparseBoolList();

  bool postfix = false;

  @override
  List<Matcher> visitAndPredicate(AndPredicateExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixAndPredicateMatcher(node, matcher));
    } else {
      return _visitSingle(
          node, (matcher) => AndPredicateMatcher(node, matcher));
    }
  }

  @override
  List<Matcher> visitAnyCharacter(AnyCharacterExpression node) {
    if (postfix) {
      return [PostfixAnyCharacterMatcher(node)];
    } else {
      return [AnyCharacterMatcher(node)];
    }
  }

  @override
  List<Matcher> visitCapture(CaptureExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixCaptureMatcher(node, matcher));
    } else {
      return _visitSingle(node, (matcher) => CaptureMatcher(node, matcher));
    }
  }

  @override
  List<Matcher> visitCharacterClass(CharacterClassExpression node) {
    if (postfix) {
      return [PostfixCharacterClassMatcher(node, inputCharacters)];
    } else {
      return [CharacterClassMatcher(node)];
    }
  }

  @override
  List<Matcher> visitLiteral(LiteralExpression node) {
    if (postfix) {
      return [PostfixLiteralMatcher(node)];
    } else {
      return [LiteralMatcher(node)];
    }
  }

  @override
  List<Matcher> visitNonterminal(NonterminalExpression node) {
    return NonterminalMatcher(node);
  }

  @override
  List<Matcher> visitNotPredicate(NotPredicateExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixNotPredicateMatcher(node, matcher));
    } else {
      return _visitSingle(
          node, (matcher) => NotPredicateMatcher(node, matcher));
    }
  }

  @override
  List<Matcher> visitOneOrMore(OneOrMoreExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixOneOrMoreMatcher(node, matcher));
    } else {
      return _visitSingle(node, (matcher) => OneOrMoreMatcher(node, matcher));
    }
  }

  @override
  List<Matcher> visitOptional(OptionalExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixOptionalMatcher(node, matcher));
    } else {
      return _visitSingle(node, (matcher) => OptionalMatcher(node, matcher));
    }
  }

  @override
  List<Matcher> visitOrderedChoice(OrderedChoiceExpression node) {
    // TODO
    throw UnimplementedError();
  }

  @override
  List<Matcher> visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final first = expressions.first;
    final matchers = first.accept(this);
    postfix = false;
    for (var i = 1; i < expressions.length; i++) {
      final child = expressions[i];
      final result = child.accept(this);
      
    }

    postfix = true;
    return matchers;
  }

  @override
  List<Matcher> visitSubterminal(SubterminalExpression node) {
    return SubterminalMatcher(node);
  }

  @override
  List<Matcher> visitTerminal(TerminalExpression node) {
    return TerminalMatcher(node);
  }

  @override
  List<Matcher> visitZeroOrMore(ZeroOrMoreExpression node) {
    if (postfix) {
      return _visitSingle(
          node, (matcher) => PostfixZeroOrMoreMatcher(node, matcher));
    } else {
      return _visitSingle(node, (matcher) => ZeroOrMoreMatcher(node, matcher));
    }
  }

  List<Matcher> _visitSingle(
      SingleExpression node, Matcher parent(Matcher matcher)) {
    final child = node.expression;
    final matchers = child.accept(this);
    for (var i = 0; i < matchers.length; i++) {
      final matcher = matchers[0];
      matchers[0] = parent(matcher);
    }

    return matchers;
  }
}
