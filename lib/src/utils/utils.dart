part of '../../utils.dart';

class Utils {
  static bool canExpressionChangeCh(
      Expression node, Set<Expression> processed) {
    if (!processed.add(node)) {
      return true;
    }

    switch (node.kind) {
      case ExpressionKind.andPredicate:
      case ExpressionKind.anyCharacter:
      case ExpressionKind.characterClass:
      case ExpressionKind.literal:
      case ExpressionKind.notPredicate:
        return false;
      case ExpressionKind.capture:
      case ExpressionKind.optional:
      case ExpressionKind.oneOrMore:
      case ExpressionKind.zeroOrMore:
        final single = node as SingleExpression;
        return canExpressionChangeCh(single.expression, processed);
      case ExpressionKind.nonterminal:
      case ExpressionKind.subterminal:
      case ExpressionKind.terminal:
        final symbol = node as SymbolExpression;
        return canExpressionChangeCh(symbol.expression!, processed);
      case ExpressionKind.orderedChoice:
        final choice = node as OrderedChoiceExpression;
        final expressions = choice.expressions;
        for (final expression in expressions) {
          if (canExpressionChangeCh(expression, processed)) {
            return true;
          }
        }

        return false;
      case ExpressionKind.sequence:
        final sequence = node as SequenceExpression;
        final expressions = sequence.expressions;
        var count = 0;
        var skipOtional = false;
        for (final expression in expressions) {
          switch (expression.kind) {
            case ExpressionKind.andPredicate:
            case ExpressionKind.notPredicate:
              continue;
            default:
          }

          if (expression.isOptional && skipOtional) {
            continue;
          }

          if (count > 0) {
            return true;
          }

          skipOtional = true;
          count++;
        }

        return false;
    }
  }

  static bool canExpressionChangePos(SequenceExpression node) {
    var count = 0;
    for (final child in node.expressions) {
      switch (child.kind) {
        case ExpressionKind.andPredicate:
        case ExpressionKind.notPredicate:
          continue;
        default:
      }

      if (child.isOptional) {
        if (count == 0) {
          count++;
        }

        continue;
      }

      if (count++ > 0) {
        return true;
      }
    }

    return false;
  }

  static String escapeString(String text, [bool quote = true]) {
    text = text.replaceAll('\\', r'\\');
    text = text.replaceAll('\b', r'\b');
    text = text.replaceAll('\f', r'\f');
    text = text.replaceAll('\n', r'\n');
    text = text.replaceAll('\r', r'\r');
    text = text.replaceAll('\t', r'\t');
    text = text.replaceAll('\v', r'\v');
    text = text.replaceAll('\'', '\\\'');
    text = text.replaceAll('\$', r'\$');
    if (!quote) {
      return text;
    }

    return '\'$text\'';
  }

  static String expr2Str(Expression expression) {
    return '${expression.runtimeType.toString().substring(0, 3)}${expression.id}: ${escapeString(expression.toString())}';
  }

  static String range2Str(RangeList range) {
    String escape(int char) {
      if (char >= 32 && char <= 127) {
        return String.fromCharCode(char);
      } else {
        return char.toString();
      }
    }

    final start = range.start;
    final end = range.end;
    if (start == end) {
      return '[${escape(start)}]';
    } else {
      return '[${escape(start)}-${escape(end)}]';
    }
  }

  static Expression? findMatcher(
      Expression expression, Set<Expression> processed) {
    if (!processed.add(expression)) {
      return null;
    }

    switch (expression.kind) {
      case ExpressionKind.anyCharacter:
      case ExpressionKind.characterClass:
      case ExpressionKind.literal:
        return expression;
      case ExpressionKind.andPredicate:
      case ExpressionKind.notPredicate:
        final predicate = expression as PrefixExpression;
        return findMatcher(predicate.expression, processed);
      case ExpressionKind.capture:
      case ExpressionKind.oneOrMore:
      case ExpressionKind.optional:
      case ExpressionKind.zeroOrMore:
        return null;
      case ExpressionKind.orderedChoice:
      case ExpressionKind.sequence:
        final multiple = expression as MultipleExpression;
        final expressions = multiple.expressions;
        if (expressions.length > 1) {
          return null;
        }

        final child = expressions.first;
        return findMatcher(child, processed);
      case ExpressionKind.nonterminal:
      case ExpressionKind.terminal:
      case ExpressionKind.subterminal:
        final symbol = expression as SymbolExpression;
        return findMatcher(symbol.expression!, processed);
    }
  }
}
