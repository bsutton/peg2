part of '../../finite_automaton.dart';

class FiniteAutomatonProcessor extends ExpressionVisitor {
  List<Expression> _active;

  State _end;

  int _id;

  State _start;

  Map<SymbolExpression, List<State>> _symbolStates;

  State process(OrderedChoiceExpression expression) {
    _active = [];
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
    _processChild(node, node.expression);
    _start.epsilon.add(_end);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _processStart(node);
    final startCharacters = Expression.allChararcters;
    _addTransitions(_start, startCharacters, _end);
    _processEnd(node, _start, _end);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _processChild(node, node.expression);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _processStart(node);
    final startCharacters = node.startCharacters;
    _addTransitions(_start, startCharacters, _end);
    _processEnd(node, _start, _end);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      _processStart(node);
      _processEnd(node, _start, _end);
    } else {
      _processStart(node);
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
      _processEnd(node, start, end);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _processSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _processChild(node, node.expression);
    _start.epsilon.add(_end);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    _processStart(node);
    final start = _start;
    final end = _end;
    final child = node.expression;
    child.accept(this);
    final middle = _createState();
    middle.epsilon.add(end);
    end.epsilon.add(middle);
    _connect(start, middle);
    child.accept(this);
    _connect(middle, end);
    _processEnd(node, start, end);
  }

  @override
  void visitOptional(OptionalExpression node) {
    _processChild(node, node.expression);
    _start.epsilon.add(_end);
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    _processStart(node);
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
    _processEnd(node, start, end);
  }

  @override
  void visitSequence(SequenceExpression node) {
    _processStart(node);
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
    _processEnd(node, start, end);
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
    _processStart(node);
    final start = _start;
    final end = _end;
    start.epsilon.add(end);
    final child = node.expression;
    child.accept(this);
    final middle = _createState();
    middle.epsilon.add(end);
    end.epsilon.add(middle);
    _connect(start, middle);
    child.accept(this);
    _connect(middle, end);
    _processEnd(node, start, end);
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
      _end.epsilon.add(end);
    }
  }

  void _connectStates(List<List<State>> states) {
    final first = states.first;
    final last = states.last;
    var prev = first[1];
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
    return state;
  }

  void _processChild(Expression parent, Expression child) {
    _processStart(parent);
    final start = _start;
    final end = _end;
    child.accept(this);
    _processEnd(parent, start, end);
  }

  void _processEnd(Expression node, State start, State end) {
    _connect(start, end);
    _start = start;
    _end = end;
    _active.remove(node);
  }

  void _processStart(Expression node) {
    _active.add(node);
    _start = _createState();
    _end = _createState();
    _addStarts(_start, node);
    _addEnds(_end, node);
  }

  void _processSymbol(SymbolExpression node) {
    if (_symbolStates.containsKey(node)) {
      final states = _symbolStates[node];
      _start = states[0];
      _end = states[1];
      return;
    }

    _processStart(node);
    final start = _start;
    final end = _end;
    _symbolStates[node] = [start, end];
    node.expression.accept(this);
    _processEnd(node, start, end);
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
