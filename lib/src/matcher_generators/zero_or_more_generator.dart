part of '../../matcher_generators.dart';

class ZeroOrMoreGenerator extends MatcherGenerator<ZeroOrMoreMatcher> {
  ZeroOrMoreGenerator(ZeroOrMoreMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    variables = {};
    final child = matcher.matcher;
    if (variable == null) {
      block.doWhile$(ref(Members.ok), (block) {
        final generator = accept(child, this);
        generator.generate(block, accept);
      });

      block.assign(Members.ok, true$);
    } else {
      void fail(CodeBlock block) {
        block.break$();
      }

      final init = literalList([], ref(child.resultType));
      final list = allocate();
      block.assignFinal(list, init);
      block.while$(true$, (block) {
        final generator = accept(child, this);
        generator.generate(block, accept);
        generatePostCode(generator, block, null, fail);
        final element = nullCheck(ref(generator.variable!), child.resultType);
        final args = [element];
        final call = methodCallExpression(ref(list), 'add', args);
        block.addStatement(call);
      });

      block.if$(ref(Members.ok).assign(true$), (block) {
        block.assign(variable!, ref(list));
      });
    }
  }
}
