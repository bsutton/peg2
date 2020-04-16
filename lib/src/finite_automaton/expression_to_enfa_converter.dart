part of '../../finite_automaton.dart';

class ExpressionToEnfaConverter extends ExpressionVisitor {
  Set<Expression> _active;

  Map<OrderedChoiceExpression, List<EnfaState>> _choiceStates;

  Map<Expression, Set<EnfaState>> _expressionStates;

  EnfaState _last;

  int _stateId;

  EnfaState convert(OrderedChoiceExpression expression) {
    _active = {};
    _choiceStates = {};
    _expressionStates = {};
    _stateId = 0;
    final s0 = _createState();
    _last = s0;
    expression.accept(this);
    _last.isFinal = true;
    final hs = HashSet<EnfaState>(equals: identical, hashCode: (e) => hashCode);
    _renumber(s0, 0, hs);
    return s0;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final s0 = _last;
    _start(node);
    final child = node.expression;
    child.accept(this);
    _end(node);
    _last = s0;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final s0 = _start(node);
    final s1 = _createState();
    final startCharacters = Expression.allChararcters;
    _addTransitions(s0, startCharacters, s1);
    _end(node, s1);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _start(node);
    final child = node.expression;
    child.accept(this);
    _end(node);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _start(node);
    final s0 = _last;
    final s1 = _createState();
    final startCharacters = node.startCharacters;
    _addTransitions(s0, startCharacters, s1);
    _end(node, s1);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    _start(node);
    final text = node.text;
    if (text.isEmpty) {
      final s0 = _last;
      final s1 = _createState();
      _connect(s0, s1);
      _end(node, s1);
    } else {
      final runes = text.runes.toList();
      final s0 = _last;
      var s1 = s0;
      for (final rune in runes) {
        final group = GroupedRangeList<bool>(rune, rune, true);
        final startCharacters = SparseBoolList();
        startCharacters.addGroup(group);
        _last = _createState();
        _addTransitions(s1, startCharacters, _last);
        s1 = _last;
      }

      _end(node);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _processSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final s0 = _last;
    _start(node);
    final child = node.expression;
    child.accept(this);
    _end(node);
    _last = s0;
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _start(node);
    final child = node.expression;
    child.accept(this);
    final s1 = _last;
    final s2 = _createState();
    _last = s2;
    _connect(s1, s2);
    child.accept(this);
    final s3 = _last;
    _connect(s3, s2);
    final s4 = _createState();
    _connect(s1, s4);
    _connect(s3, s4);
    _end(node, s4);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _start(node);
    final s0 = _last;
    final s1 = _createState();
    _connect(s0, s1);
    _last = s1;
    final child = node.expression;
    child.accept(this);
    final s2 = _last;
    final s3 = _createState();
    _connect(s0, s3);
    final s4 = _createState();
    _connect(s3, s4);
    final s5 = _createState();
    _connect(s2, s5);
    _connect(s4, s5);
    _end(node, s5);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final states = _getChoiceStates(node);
    if (states[0] != null) {
      _last = states[1];
    }

    _start(node);
    states[0] = _last;
    states[1] = _createState();
    final s0 = _last;
    final lastStates = <EnfaState>[];
    for (final child in node.expressions) {
      final s1 = _createState();
      _connect(s0, s1);
      _last = s1;
      child.accept(this);
      lastStates.add(_last);
    }

    final s3 = states[1];
    for (final s2 in lastStates) {
      _connect(s2, s3);
    }

    _end(node, s3);
  }

  @override
  void visitSequence(SequenceExpression node) {
    _start(node);
    for (final child in node.expressions) {
      child.accept(this);
    }

    _end(node);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _processSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _processSymbol(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    _start(node);
    final s0 = _last;
    final s1 = _createState();
    _connect(s0, s1);
    _last = s1;
    final child = node.expression;
    child.accept(this);
    final s2 = _last;
    _connect(s2, s1);
    final s3 = _createState();
    _connect(s0, s3);
    _connect(s2, s3);
    _end(node, s3);
  }

  void _addActive(EnfaState state) {
    state.active.addAll(_active);
    _registerExpressionStates(state, _active);
  }

  void _addMovement(
      Expression expression, EnfaState from, EnfaState to, RangeList range) {
    final movements = from.movements;
    var value = movements[expression];
    if (value == null) {
      value = [];
      movements[expression] = value;
    }

    final start = range.start;
    final end = range.end;
    var found = false;
    for (final x in value) {
      if (start == x.start && end == x.end && x.key == to) {
        found = true;
        break;
      }
    }

    if (!found) {
      final movement = GroupedRangeList(start, end, to);
      value.add(movement);
    }
  }

  void _addTransitions(
      EnfaState from, SparseBoolList startCharacters, EnfaState to) {
    final active = from.active;
    final transitions = from.transitions;
    for (final range in startCharacters.groups) {
      for (final group in transitions.getAllSpace(range)) {
        var key = group.key;
        if (key == null) {
          key = [to];
        } else {
          if (!key.contains(to)) {
            key = key.toList();
            key.add(to);
          }
        }

        final start = group.start;
        final end = group.end;
        final newGroup = GroupedRangeList(start, end, key);
        transitions.addGroup(newGroup);
      }

      for (final expression in active) {
        _addMovement(expression, from, to, range);
      }
    }
  }

  void _connect(EnfaState from, EnfaState to) {
    from.states.add(to);
  }

  EnfaState _createState([bool active = true]) {
    final state = EnfaState(_stateId++);
    if (active) {
      _addActive(state);
    }

    return state;
  }

  void _end(Expression node, [EnfaState state]) {
    state ??= _last;
    _addActive(state);
    state.ends.add(node);
    _active.remove(node);
    _last = state;
  }

  List<EnfaState> _getChoiceStates(OrderedChoiceExpression node) {
    var result = _choiceStates[node];
    if (result == null) {
      result = [null, null];
      _choiceStates[node] = result;
    }

    return result;
  }

  Set<EnfaState> _getExpressionStates(Expression expression) {
    var result = _expressionStates[expression];
    if (result == null) {
      result = {};
      _expressionStates[expression] = result;
    }

    return result;
  }

  void _processSymbol(SymbolExpression node) {
    final expression = node.expression;
    final states = _getChoiceStates(expression);
    final s0 = _last;
    if (states[0] == null) {
      //final active = _active.toSet();
      ///_active.clear();
      _last = _createState();
      expression.accept(this);
      //_active = active;
    }

    //_last = s0;
    //_start(node);
    final s1 = states[0];
    _last = s1;
    _start(node);
    _connect(s0, s1);
    final s3 = states[1];
    //final s4 = _createState();
    //_connect(s3, s4);
    //_last = s4;
    _last = s3;

    final ruleStates = _getExpressionStates(expression);
    final symbolStates = _getExpressionStates(node);
    for (final ruleState in ruleStates) {
      for (final symbolState in symbolStates) {
        symbolState.active.addAll(ruleState.active);
      }

      ruleState.active.addAll(_active);
      final ruleMovements = ruleState.movements[expression];
      if (ruleMovements != null) {
        for (final movement in ruleMovements.toList()) {
          for (final expression in _active) {
            final to = movement.key;
            _addMovement(expression, ruleState, to, movement);
          }
        }
      }
    }

    _end(node);
  }

  void _registerExpressionStates(
      EnfaState state, Iterable<Expression> expressions) {
    for (final expression in expressions) {
      final states = _getExpressionStates(expression);
      states.add(state);
    }
  }

  int _renumber(EnfaState state, int id, Set<EnfaState> processed) {
    if (!processed.add(state)) {
      return id;
    }

    state.id = id++;
    for (final state in state.states) {
      id = _renumber(state, id, processed);
    }

    final transitions = state.transitions;
    for (final group in transitions.groups) {
      for (final state in group.key) {
        id = _renumber(state, id, processed);
      }
    }

    return id;
  }

  EnfaState _start(Expression node, [EnfaState state]) {
    state ??= _last;
    _active.add(node);
    state.starts.add(node);
    _addActive(state);
    return state;
  }
}
