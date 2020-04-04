part of '../../expression_analyzers.dart';

class ExpressionStartCharactersResolver extends ExpressionVisitor {
  bool _hasModifications;

  void resolve(List<ProductionRule> rules) {
    if (rules == null) {
      throw ArgumentError.notNull('rules');
    }

    _hasModifications = true;
    while (_hasModifications) {
      _hasModifications = false;
      for (var rule in rules) {
        rule.expression.accept(this);
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _addCharacters(node, Expression.allChararcters);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _addCharacters(node, node.ranges);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      _addAllCharactersWithEof(node);
    } else {
      final characters = SparseBoolList();
      int c;
      final leading = text.codeUnitAt(0);
      if ((leading & 0xFC00) == 0xD800 && text.length > 1) {
        final trailing = text.codeUnitAt(1);
        if ((trailing & 0xFC00) == 0xDC00) {
          c = 0x10000 + ((leading & 0x3FF) << 10) + (trailing & 0x3FF);
        } else {
          c = leading;
        }
      } else {
        c = leading;
      }

      final group = GroupedRangeList<bool>(c, c, true);
      characters.addGroup(group);
      _addCharacters(node, characters);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    final rule = node.expression.rule;
    final child = rule.expression;
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    SparseBoolList childCharacters;
    if (child is AnyCharacterExpression) {
      childCharacters = child.startCharacters;
    } else if (child is CharacterClassExpression) {
      childCharacters = child.startCharacters;
    } else if (child is LiteralExpression) {
      final text = child.text;
      if (text.length == 1) {
        final rune = text.runes.first;
        childCharacters = SparseBoolList();
        final group = GroupedRangeList(rune, rune, true);
        childCharacters.addGroup(group);
      }
    }

    if (childCharacters != null) {
      final startCharacters = SparseBoolList();
      for (final group in Expression.allChararctersWithEof.groups) {
        startCharacters.addGroup(group);
      }

      for (final range in childCharacters.groups) {
        final group = GroupedRangeList(range.start, range.end, false);
        startCharacters.setGroup(group);
      }

      _addCharacters(node, startCharacters);
    } else {
      _addAllCharactersWithEof(node);
    }
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
      _addCharacters(node, child.startCharacters);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    final affected = <Expression>[];
    var skip = false;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
      if (!skip) {
        affected.add(child);
        if (!child.isOptional) {
          skip = true;
        }
      }
    }

    for (final child in affected) {
      _addCharacters(node, child.startCharacters);
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final rule = node.expression.rule;
    final child = rule.expression;
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final rule = node.expression.rule;
    final child = rule.expression;
    _addCharacters(node, child.startCharacters);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
  }

  void _addAllCharactersWithEof(Expression node) {
    _addCharacters(node, Expression.allChararctersWithEof);
  }

  void _addCharacters(Expression node, SparseBoolList characters) {
    final startCharacters = node.startCharacters;
    for (final range in characters.groups) {
      for (final group in startCharacters.getAllSpace(range)) {
        if (!group.key) {
          _hasModifications = true;
          final start = group.start;
          final end = group.end;
          final newGroup = GroupedRangeList(start, end, true);
          startCharacters.addGroup(newGroup);
        }
      }
    }
  }
}
