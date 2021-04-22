part of '../../matcher_generators.dart';

class CaptureGenerator extends MatcherGenerator<CaptureMatcher> {
  CaptureGenerator(CaptureMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    final child = matcher.matcher;
    if (variable == null) {
      final generator = accept(matcher.matcher, this);
      generator.addVariables(this);
      generator.generate(block, accept);
    } else {
      final start = store(block, Members.pos);
      final generator = accept(child, this);
      generator.addVariables(this);
      generator.generate(block, accept);
      block.if$(ref(Members.ok), (block) {
        final args = [ref(start), ref(Members.pos)];
        final call =
            methodCallExpression(ref(Members.source), 'substring', args);
        block.assign(variable!, call);
      });
    }
  }
}
