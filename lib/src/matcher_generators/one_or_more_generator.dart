part of '../../matcher_generators.dart';

class OneOrMoreGenerator extends MatcherGenerator<OneOrMoreMatcher> {
  OneOrMoreGenerator(OneOrMoreMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    variables = {};
    final child = matcher.matcher;
    if (variable == null) {
      final count = allocate();
      block.assignVar(count, literal(0));
      block.doWhile$(ref(Members.ok), (block) {
        final generator = accept(child, this);
        generator.generate(block, accept);
        final inc = postfixExpression(ref(count), '++');
        block.addStatement(inc);
      });

      block.assign(Members.ok, ref(count).notEqualTo(literal(1)));
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

      final control = ref(list).property('isNotEmpty');
      block.if$(control, (block) {
        block.assign(variable!, ref(list));
        block.assign(Members.ok, true$);
      });
    }
  }
}
