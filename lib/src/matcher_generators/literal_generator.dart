part of '../../matcher_generators.dart';

class LiteralGenerator extends MatcherGenerator<LiteralMatcher> {
  LiteralGenerator(LiteralMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    allocateVariable();
    final expression = matcher.expression;
    final text = expression.text;
    if (text.isEmpty) {
      declareVariable(block);
      block.tryAssign(variable, () => ref(''));
      block.assign(Members.ok, true$);
    } else if (text.length == 1) {
      final recognizerGenerator = RecognizerGenerator(
          list: expression.startCharacters, maxCount: 10, variable: Members.ch);
      final control = recognizerGenerator.generate();
      if (control == null) {
        throw StateError('Internal error');
      }

      declareVariable(block);
      block.assign(Members.ok, false$);
      block.if$(control, (block) {
        final args = [literalString(text)];
        final call = callExpression(Members.nextChar, args);
        if (variable == null) {
          block.addStatement(call);
        } else {
          block.assign(variable!, call);
        }
      });
    } else {
      declareVariable(block);
      final args = [literalString(text), ref(Members.pos)];
      final call =
          methodCallExpression(ref(Members.source), 'startsWith', args);
      block.assign(Members.ok, call);
      block.if$(ref(Members.ok), (block) {
        if (variable != null) {
          block.assign(variable!, literalString(text));
        }

        final pos =
            binaryExpression(ref(Members.pos), '+=', literal(text.length));
        final args = [pos];
        final call = callExpression(Members.getChar, args);
        block.assign(Members.ch, call);
      });
    }
  }
}
