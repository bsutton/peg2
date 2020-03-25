part of '../../finite_automaton.dart';

class FiniteAutomatonProcessor extends ExpressionVisitor {
  List<Expression> _active;

  State _end;

  List<State> _epsilon;

  int _id;

  State _start;

  Map<SymbolExpression, List<State>> _symbolStates;

  State process(OrderedChoiceExpression expression) {
    _active = [];
    _epsilon = [];
    _id = 0;
    _symbolStates = {};
    final start = _createState();
    final end = _createState();
    expression.accept(this);
    _connect(start, end);
    return start;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _processChild(node, node.expression, true);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _processStart(node, false);
    final startCharacters = Expression.allChararcters;
    _addTransitions(_start, startCharacters, _end);
    _processEnd(node, _start, _end, false);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _processChild(node, node.expression, false);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _processStart(node, false);
    final startCharacters = node.startCharacters;
    _addTransitions(_start, startCharacters, _end);
    _processEnd(node, _start, _end, false);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      _processStart(node, true);
      _processEnd(node, _start, _end, false);
    } else {
      _processStart(node, false);
      final start = _start;
      final end = _end;
      final runes = text.runes.toList();
      final states = <List<State>>[];
      for (var i = 0; i < runes.length; i++) {
        final rune = runes[i];
        final start = _createState();
        final end = _createState();
        final group = GroupedRangeList<bool>(rune, rune, true);
        final startCharacters = SparseBoolList();
        startCharacters.addGroup(group);
        _addTransitions(start, startCharacters, end);
        states.add([start, end]);
      }

      _connectStates(states);
      _processEnd(node, start, end, false);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _processSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _processChild(node, node.expression, true);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _processStart(node, false);
    final start = _start;
    final end = _end;
    final child = node.expression;
    child.accept(this);
    final middle = _createState();
    start.epsilon.add(_start);
    _end.epsilon.add(middle);
    _epsilon.add(end);
    child.accept(this);
    _epsilon.remove(end);
    middle.epsilon.add(_start);
    _end.epsilon.add(end);
    end.epsilon.add(middle);
    _processEnd(node, start, end, false);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _processChild(node, node.expression, true);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    _processStart(node, false);
    final start = _start;
    final end = _end;
    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      _connect(start, end);
    }

    _start = start;
    _end = end;
    _processEnd(node, start, end, true);
  }

  @override
  void visitSequence(SequenceExpression node) {
    _processStart(node, false);
    final start = _start;
    final end = _end;
    final expressions = node.expressions;
    final states = <List<State>>[];
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      states.add([_start, _end]);
    }

    _connectStates(states);
    _processEnd(node, start, end, true);
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
    _processStart(node, true);
    final start = _start;
    final end = _end;
    final child = node.expression;
    child.accept(this);
    final middle = _createState();
    _connect(start, middle);
    child.accept(this);
    _connect(middle, end);
    end.epsilon.add(middle);
    _processEnd(node, start, end, true);
  }

  void _addEnds(State state, Expression expression) {
    state.ends.add(expression);
  }

  void _addEpsilon(State from, State to) {
    from.epsilon.add(to);
  }

  void _addStarts(State state, Expression expression) {
    state.starts.add(expression);
  }

  void _addTransitions(
      State state, SparseBoolList startCharacters, State transition) {
    final transitions = state.transitions;
    if (transitions.groupCount != 0) {
      throw StateError('State already has transitions');
    }

    for (final src in startCharacters.groups) {
      final dest = GroupedRangeList<State>(src.start, src.end, transition);
      transitions.addGroup(dest);
    }
  }

  void _connect(State start, State end) {
    if (start != _start) {
      start.epsilon.add(_start);
    }

    if (end != _end) {
      end.epsilon.add(_end);
    }
  }

  void _connectStates(List<List<State>> states) {
    final first = states.first;
    final last = states.last;
    var prev = first[0];
    for (var i = 1; i < states.length; i++) {
      final state = states[i];
      prev.epsilon.add(state[0]);
      prev = state[1];
    }

    _start = first[0];
    _end = last[1];
  }

  State _createState() {
    final state = State(_id++);
    state.active.addAll(_active);
    state.epsilon.addAll(_epsilon);
    return state;
  }

  void _processChild(Expression parent, Expression child, bool isEpsilon) {
    _processStart(parent, isEpsilon);
    final start = _start;
    final end = _end;
    child.accept(this);
    _processEnd(parent, start, end, isEpsilon);
  }

  void _processEnd(Expression node, State start, State end, bool isEpsilon) {
    _connect(start, end);
    _start = start;
    _end = end;
    if (isEpsilon) {
      _epsilon.remove(end);
    }

    _active.remove(node);
  }

  void _processStart(Expression node, bool isEpsilon) {
    _active.add(node);
    _start = _createState();
    _end = _createState();
    _addStarts(_start, node);
    _addEnds(_end, node);
    if (isEpsilon) {
      _epsilon.add(_end);
      _start.epsilon.add(_end);
    }
  }

  void _processSymbol(SymbolExpression node) {
    if (_symbolStates.containsKey(node)) {
      final states = _symbolStates[node];
      _start = states[0];
      _end = states[1];
      return;
    }

    _processStart(node, false);
    final start = _start;
    final end = _end;
    _symbolStates[node] = [start, end];
    node.expression.accept(this);
    _processEnd(node, start, end, false);
  }
}

class State {
  final id;

  final active = <Expression>{};

  final ends = <Expression>{};

  final epsilon = <State>[];

  final starts = <Expression>{};

  final transitions = SparseList<State>();

  State(this.id);

  @override
  String toString() {
    return '$id';
  }
}
