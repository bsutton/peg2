part of '../../finite_automaton.dart';

class ExpressionToEnfaConverter extends ExpressionVisitor {
  List<Expression> _active;

  Map<OrderedChoiceExpression, List<EnfaState>> _choiceStates;

  EnfaState _last;

  int _id;

  void Function(SymbolExpression, EnfaState, EnfaState) _separate;

  EnfaState convert(OrderedChoiceExpression expression,
      Function(SymbolExpression, EnfaState, EnfaState) separate) {
    _active = [];
    _id = 0;
    _choiceStates = {};
    _separate = separate;
    final s0 = _createState();
    _last = s0;
    expression.accept(this);
    _last.isFinal = true;
    return s0;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _start(node);
    _end(node);
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
    _start(node);
    _end(node);
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
      states[1] = _getChoiceEndState(node);
      return;
    }

    states[0] = _last;
    _start(node);
    final s0 = _last;
    final last = <EnfaState>[];
    for (final child in node.expressions) {
      final next = _createState();
      _connect(s0, next);
      _last = next;
      child.accept(this);
      last.add(_last);
    }

    final s1 = _getChoiceEndState(node);
    for (final state in last) {
      _connect(state, s1);
    }

    _end(node, s1);
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

  void _addEnds(EnfaState state, Expression node) {
    state.ends.add(node);
  }

  void _addTransitions(
      EnfaState from, SparseBoolList startCharacters, EnfaState to) {
    final transitions = from.transitions;
    for (final range in startCharacters.groups) {
      for (final group in transitions.getAllSpace(range)) {
        var key = group.key;
        key ??= [];
        if (!key.contains(to)) {
          key.add(to);
        }

        if (group.key == null) {
          final start = group.start;
          final end = group.end;
          final newGroup = GroupedRangeList(start, end, key);
          transitions.addGroup(newGroup);
        }
      }
    }
  }

  void _connect(EnfaState from, EnfaState to) {
    from.states.add(to);
  }

  EnfaState _createState() {
    final state = EnfaState(_id++);
    state.active.addAll(_active);
    return state;
  }

  void _end(Expression node, [EnfaState state]) {
    state ??= _last;
    _addEnds(state, node);
    _active.remove(node);
    _last = state;
  }

  EnfaState _getChoiceEndState(OrderedChoiceExpression node) {
    final states = _getChoiceStates(node);
    var result = states[1];
    if (result == null) {
      result = _createState();
      states[1] = result;
    }

    return result;
  }

  List<EnfaState> _getChoiceStates(OrderedChoiceExpression node) {
    var result = _choiceStates[node];
    if (result == null) {
      result = [null, null];
      _choiceStates[node] = result;
    }

    return result;
  }

  void _processSymbol(SymbolExpression node) {
    final expression = node.expression;
    final states = _getChoiceStates(expression);
    if (states[0] == null) {
      final s0 = _last;
      s0.starts.add(node);
      _last = _createState();
      expression.accept(this);
      _separate(node, s0, states[0]);
      final s1 = _last;
      final s2 = _createState();
      _connect(s1, s2);
      s2.ends.add(node);
      _last = s2;
    } else {
      final s0 = _last;
      s0.starts.add(node);
      final s1 = states[0];
      _separate(node, s0, s1);
      final s2 = _getChoiceEndState(expression);
      final s3 = _createState();
      _separate(node, s2, s3);
      s3.ends.add(node);
      _last = s3;
    }
  }

  EnfaState _start(Expression node) {
    _active.add(node);
    _last.starts.add(node);
    _last.active.addAll(_active);
    return _last;
  }
}
