part of '../../finite_automaton.dart';

class FiniteAutomatonProcessor extends ExpressionVisitor {
  List<Expression> _active;

  State _end;

  List<State> _epsilon;

  List<Expression> _recursive;

  State _start;

  State process(
      OrderedChoiceExpression expression, List<Expression> recursive) {
    _active = [];
    _epsilon = [];
    _recursive = recursive;
    final start = _createState();
    expression.accept(this);
    final end = _createState();
    _addEpsilon(start, _start);
    _addEpsilon(_end, end);
    return start;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _processChild(node, node.expression, true);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    _active.add(node);
    _start = _createState();
    _addStarts(_start, node);
    _end = _createState();
    final startCharacters = Expression.allChararcters;
    _addTransitions(_start, startCharacters, _end);
    _addEnds(_end, node);
    _active.remove(node);
  }

  @override
  void visitCapture(CaptureExpression node) {
    _processChild(node, node.expression, false);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    _active.add(node);
    _start = _createState();
    _addStarts(_start, node);
    _end = _createState();
    final startCharacters = node.startCharacters;
    _addTransitions(_start, startCharacters, _end);
    _addEnds(_end, node);
    _active.remove(node);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    if (text.isEmpty) {
      _processStart(node, true);
      _processEnd(node, _start, _end, true);
    } else {
      _processStart(node, false);
      final start = _start;
      final end = _end;
      final runes = text.runes.toList();
      var prev = _start;
      State next;
      for (var i = 0; i < runes.length; i++) {
        final rune = runes[i];
        final group = GroupedRangeList<bool>(rune, rune, true);
        final startCharacters = SparseBoolList();
        startCharacters.addGroup(group);
        if (i < runes.length - 1) {
          next = _createState();
        } else {
          next = end;
        }

        _addTransitions(prev, startCharacters, next);
        prev = next;
      }

      _processEnd(node, start, end, false);
    }
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _processChild(node, node.expression, false);
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
    if (_start.starts.contains(node)) {
      _processEnd(node, _start, _end, false);
      _recursive.add(node);
      return;
    }

    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      child.accept(this);
      start.epsilon.add(_start);
      end.epsilon.add(_end);
    }

    _processEnd(node, start, end, true);
  }

  @override
  void visitSequence(SequenceExpression node) {
    //
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _processChild(node, node.expression, false);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _processChild(node, node.expression, false);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    _processStart(node, true);
    final start = _start;
    final end = _end;
    final child = node.expression;
    child.accept(this);
    final middle = _createState();
    start.epsilon.add(_start);
    _end.epsilon.add(middle);
    child.accept(this);
    middle.epsilon.add(_start);
    _end.epsilon.add(end);
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
    throw UnimplementedError();
  }

  State _createState() {
    final state = State();
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
    _addEpsilon(start, _start);
    _addEpsilon(_end, end);
    _start = start;
    _end = end;
    if (isEpsilon) {
      _epsilon.remove(end);
    }

    _active.remove(node);
  }

  void _processStart(Expression node, bool isEpsilon) {
    _active.add(node);
    _end = _createState();
    if (isEpsilon) {
      _epsilon.add(_end);
    }

    _start = _createState();
    _addStarts(_start, node);
    _addEnds(_end, node);
  }
}

class State {
  final active = <Expression>{};

  final ends = <Expression>{};

  final epsilon = <State>[];

  final starts = <Expression>{};

  final transitions = SparseList<List<State>>();
}
