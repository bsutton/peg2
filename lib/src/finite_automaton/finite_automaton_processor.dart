part of '../../finite_automaton.dart';

class FiniteAutomatonProcessor extends ExpressionVisitor {
  Set<Expression> _active;

  State _end;

  State _start;

  State process(OrderedChoiceExpression expression) {
    _active = {};
    _start = State();
    expression.accept(this);
    _end = State();
    return _start;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    // TODO: implement visitAndPredicate
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final startCharacters = Expression.allChararcters;
    _addStarts(_start, node);
    final next = _createState();
    _addTransitions(_start, startCharacters, next);
    _addEpsilon(next, _end);
    _addEnds(_end, node);
  }

  @override
  void visitCapture(CaptureExpression node) {
    final child = node.expression;
    _addStarts(_start, node);
    child.accept(this);
    _addEnds(_end, node);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final startCharacters = node.startCharacters;
    _addStarts(_start, node);
    final next = _createState();
    _addTransitions(_start, startCharacters, next);
    _addEpsilon(next, _end);
    _addEnds(_end, node);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      final startCharacters = Expression.allChararcters;
      _addStarts(_start, node);
      final next = _createState();
      _addTransitions(_start, startCharacters, next);
      _addEpsilon(next, _end);
      _addEnds(_end, node);
    } else {
      //
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    // TODO: implement visitNonterminal
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    // TODO: implement visitNotPredicate
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    // TODO: implement visitOneOrMore
  }

  @override
  void visitOptional(OptionalExpression node) {}

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    if (_start.starts.contains(node)) {
      // TODO:
      throw StateError('Left recursion call of rule: ${node.rule.name}');
    }

    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    // TODO: implement visitSequence
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    // TODO: implement visitSubterminal
  }

  @override
  void visitTerminal(TerminalExpression node) {
    // TODO: implement visitTerminal
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {}

  void _addActive(State state, Expression expression) {
    _active.add(expression);
    state.active.add(expression);
  }

  void _addEnds(State state, Expression expression) {
    _addActive(state, expression);
    state.ends.add(expression);
    _active.remove(expression);
  }

  void _addEpsilon(State state, State epsilon) {
    state.epsilon.add(epsilon);
  }

  void _addStarts(State state, Expression expression) {
    _addActive(state, expression);
    state.starts.add(expression);
  }

  void _addTransitions(
      State state, SparseBoolList startCharacters, State transition) {
    throw UnimplementedError();
  }

  State _createState() {
    final result = State();
    result.active.addAll(_active);
    return result;
  }
}

class State {
  final active = <Expression>{};

  final ends = <Expression>{};

  final epsilon = <State>[];

  final starts = <Expression>{};

  final transitions = SparseList<List<State>>();
}
