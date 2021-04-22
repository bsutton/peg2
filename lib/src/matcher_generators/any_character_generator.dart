part of '../../matcher_generators.dart';

class AnyCharacterGenerator extends MatcherGenerator<AnyCharacterMatcher> {
  AnyCharacterGenerator(AnyCharacterMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    allocateVariable();
    final call = callExpression(Members.matchAny);
    if (isVariableDeclared) {
      block.assign(variable!, call);
    } else {
      block.callAndTryAssignFinal(variable, call);
    }
  }
}
