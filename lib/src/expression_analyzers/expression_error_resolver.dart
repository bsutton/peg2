part of '../../expression_analyzers.dart';

class ExpressionErrorResolver extends ExpressionVisitor<void> {
  final List<_ExpressionError> _errors = [];

  void resolve(List<ProductionRule> rules) {
    _errors.clear();
    for (var rule in rules) {
      final expression = rule.expression;
      expression.accept(this);
    }

    if (_errors.isNotEmpty) {
      final sink = StringBuffer();
      for (final error in _errors) {
        final parent = error.parent;
        final child = error.child;
        final cause = error.cause;
        final effect = error.effect;
        sink.writeln('Expression errors:');
        sink.write('Rule: ');
        sink.writeln(parent.rule!.name);
        if (child == null) {
          sink.write('Expression: ');
        } else {
          sink.write('Parent: ');
        }

        sink.writeln(parent);
        if (child != null) {
          sink.write('Child: ');
          sink.writeln(child);
        }

        sink.write('Cause: ');
        sink.writeln(cause);
        sink.write('Effect: ');
        sink.writeln(effect);
        throw FormatException(sink.toString());
      }
    }
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCapture(CaptureExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitLiteral(LiteralExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    node.visitChildren(this);
    _checkInfiniteLoop(node);
  }

  @override
  void visitOptional(OptionalExpression node) {
    node.visitChildren(this);
    final child = node.expression;
    if (child.isOptional) {
      final cause = 'Both parent and child are optional expressions';
      final effect = 'The parent expression always succeeds';
      _addError(node, child, cause, effect);
    }
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    node.visitChildren(this);
    final expressions = node.expressions;
    for (var i = 0; i < expressions.length; i++) {
      final child = expressions[i];
      if (expressions.length > 1) {
        if (child.isSuccessful) {
          final cause = 'One of the child expressions always succeeds';
          final effect = 'Other child expressions will never be applied';
          _addError(node, child, cause, effect);
        }
      }
    }
  }

  @override
  void visitSequence(SequenceExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    node.visitChildren(this);
  }

  void _addError(
      Expression parent, Expression? child, String cause, String effect) {
    final error = _ExpressionError(parent, child, cause, effect);
    _errors.add(error);
  }

  void _checkInfiniteLoop(SingleExpression node) {
    final child = node.expression;
    if (child.isSuccessful) {
      final cause = 'Child expression always succeeds';
      final effect = 'Infinite loop';
      _addError(node, child, cause, effect);
    }
  }
}

class _ExpressionError {
  String cause;

  final Expression? child;

  String effect;

  final Expression parent;

  _ExpressionError(this.parent, this.child, this.cause, this.effect);
}
