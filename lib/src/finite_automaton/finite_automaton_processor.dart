part of '../../finite_automaton.dart';

class FiniteAutomatonProcessor extends ExpressionVisitor {
  List<Expression> _active;

  ENfaState _last;

  int _id;

  Map<SymbolExpression, List<ENfaState>> _symbolStates;

  ENfaState process(OrderedChoiceExpression expression) {
    _active = [];
    _id = 0;
    _symbolStates = {};
    final s0 = _createState();
    _last = s0;
    expression.accept(this);
    _last.accept = true;
    return s0;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    throw null;
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
    throw null;
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
    _start(node);
    final s0 = _last;
    final last = <ENfaState>[];
    for (final child in node.expressions) {
      final next = _createState();
      _connect(s0, next);
      _last = next;
      child.accept(this);
      last.add(_last);
    }

    final s1 = _createState();
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

  void _addEnds(ENfaState state, Expression node) {
    state.ends.add(node);
  }

  void _addTransitions(
      ENfaState state, SparseBoolList startCharacters, ENfaState transition) {
    final transitions = state.transitions;
    if (transitions.groupCount != 0) {
      throw StateError('State already has transitions');
    }

    for (final src in startCharacters.groups) {
      final dest = GroupedRangeList<ENfaState>(src.start, src.end, transition);
      transitions.addGroup(dest);
    }
  }

  void _connect(ENfaState from, ENfaState to) {
    from.states.add(to);
  }

  ENfaState _createState() {
    final state = ENfaState(_id++);
    state.active.addAll(_active);
    return state;
  }

  void _end(Expression node, [ENfaState state]) {
    state ??= _last;
    _addEnds(state, node);
    _active.remove(node);
    _last = state;
  }

  void _processSymbol(SymbolExpression node) {
    if (_symbolStates.containsKey(node)) {
      final states = _symbolStates[node];
      final s1 = states[0];
      final s2 = states[1];
      _connect(_last, s1);
      _last = s2;
      return;
    }

    _start(node);
    final s1 = _createState();
    _connect(_last, s1);
    final s2 = _createState();
    _symbolStates[node] = [s1, s2];
    node.expression.accept(this);
    _end(node, s2);
  }

  ENfaState _start(Expression node) {
    _active.add(node);
    _last.active.addAll(_active);
    return _last;
  }
}
