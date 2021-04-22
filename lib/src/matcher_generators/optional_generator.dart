part of '../../matcher_generators.dart';

class OptionalGenerator extends MatcherGenerator<OptionalMatcher> {
  OptionalGenerator(OptionalMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    allocateVariable();
    final child = matcher.matcher;
    final generator = accept(child, this);
    generator.addVariables(this);
    generator.variable = variable;
    generator.generate(block, accept);
    block.assign(Members.ok, true$);
  }
}
