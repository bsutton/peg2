part of '../../matcher_generators.dart';

class CharacterClassGenerator extends MatcherGenerator<CharacterClassMatcher> {
  CharacterClassGenerator(CharacterClassMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    allocateVariable();
    final expression = matcher.expression;
    final recognizerGenerator = RecognizerGenerator(
        list: expression.startCharacters, maxCount: 10, variable: Members.ch);
    final control = recognizerGenerator.generate();
    if (control == null) {
      final range = allocate();
      final ranges = <int>[];
      for (final group in expression.ranges.groups) {
        ranges.add(group.start);
        ranges.add(group.end);
      }

      block.assignConst(range, literalList(ranges));
      final args = [ref(range)];
      final call = callExpression(Members.matchRanges, args);
      if (isVariableDeclared) {
        block.assign(variable!, call);
      } else {
        block.callAndTryAssignFinal(variable, call);
      }
    } else {
      declareVariable(block);
      block.assign(Members.ok, false$);
      block.if$(control, (block) {
        final args = [ref(Members.ch)];
        final call = callExpression(Members.nextChar, args);
        if (variable == null) {
          block.addStatement(call);
        } else {
          block.assign(variable!, call);
        }
      });
    }
  }
}
