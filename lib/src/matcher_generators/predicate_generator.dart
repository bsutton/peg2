part of '../../matcher_generators.dart';

abstract class PredicateGenerator<E extends PredicateMatcher>
    extends MatcherGenerator<E> {
  final BitFlagGenerator failures;

  PredicateGenerator(E matcher, this.failures) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    final expression = matcher.expression;
    final rule = expression.rule!;
    final child = expression.expression;
    final isNotPredicate = expression.kind == ExpressionKind.notPredicate;
    final childKind = child.kind;
    var test = false$;
    if (childKind == ExpressionKind.anyCharacter) {
      if (isNotPredicate) {
        test = ref(Members.ch).equalTo(literal(Expression.eof));
      } else {
        test = ref(Members.ch).notEqualTo(literal(Expression.eof));
      }
    } else if (childKind == ExpressionKind.characterClass) {
      final ranges = (child as CharacterClassExpression).ranges;
      if (ranges.groupCount == 1) {
        final group = ranges.groups.first;
        final start = group.start;
        final end = group.end;
        if (start == end) {
          if (isNotPredicate) {
            test = ref(Members.ch).notEqualTo(literal(start));
          } else {
            test = ref(Members.ch).equalTo(literal(start));
          }
        }
      }
    } else if (childKind == ExpressionKind.literal) {
      final text = (child as LiteralExpression).text;
      final args = [literalString(text), ref(Members.pos)];
      test = methodCallExpression(ref(Members.source), 'startsWith', args);
      if (isNotPredicate) {
        test = test.negate();
      }
    }

    if (test != false$) {
      block.assign(Members.ok, test);
    } else {
      store(block, Members.ch);
      store(block, Members.pos);
      if (rule.kind == ProductionRuleKind.nonterminal) {
        store(block, Members.failStart);
        for (final variable in failures.variables) {
          store(block, variable);
        }
      }

      final generator = accept(matcher.matcher, this);
      generator.addVariables(this);
      generator.generate(block, accept);
      restoreAll(block);
      if (expression.kind == ExpressionKind.notPredicate) {
        block.assign(Members.ok, ref(Members.ok).negate());
      }
    }
  }
}
