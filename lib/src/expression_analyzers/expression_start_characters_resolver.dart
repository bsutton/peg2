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
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _addAllCharacters(node);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _addCharacters(node, node.ranges);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      _addAllCharacters(node);
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
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final child = node.expression;
    child.accept(this);
    _addAllCharacters(node);
    _setCanMatchEof(node, true);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _addCharacters(node, child.startCharacters);
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitOptional(OptionalExpression node) {
    final child = node.expression;
    child.accept(this);
    _addAllCharacters(node);
    _setCanMatchEof(node, true);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final expressions = node.expressions;
    final length = expressions.length;
    for (var i = 0; i < length; i++) {
      final child = expressions[i];
      child.accept(this);
      _addCharacters(node, child.startCharacters);
      _setCanMatchEof(node, child.canMatchEof);
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
      _setCanMatchEof(node, child.canMatchEof);
    }
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    final rule = node.expression.rule;
    final child = rule.expression;
    _addCharacters(node, child.startCharacters);
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    final rule = node.expression.rule;
    final child = rule.expression;
    _addCharacters(node, child.startCharacters);
    _setCanMatchEof(node, child.canMatchEof);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final child = node.expression;
    child.accept(this);
    _addAllCharacters(node);
    _setCanMatchEof(node, true);
  }

  void _addAllCharacters(Expression node) {
    final characters = SparseBoolList();
    final group = GroupedRangeList<bool>(0, 0x10ffff, true);
    characters.addGroup(group);
    _addCharacters(node, characters);
  }

  void _addCharacters(Expression node, SparseBoolList characters) {
    final startCharacters = node.startCharacters;
    var isEqual = true;
    for (final group in characters.getGroups()) {
      for (final group in startCharacters.getAllSpace(group)) {
        if (!group.key) {
          isEqual = false;
          break;
        }
      }
    }

    if (!isEqual) {
      for (final group in characters.getGroups()) {
        startCharacters.addGroup(group);
      }

      _hasModifications = true;
    }
  }

  void _setCanMatchEof(Expression node, bool canMatchEof) {
    if (canMatchEof) {
      if (node.canMatchEof != canMatchEof) {
        node.canMatchEof = canMatchEof;
        _hasModifications = true;
      }
    }
  }
}
