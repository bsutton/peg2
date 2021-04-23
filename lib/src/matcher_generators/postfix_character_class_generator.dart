part of '../../matcher_generators.dart';

class PostfixCharacterClassGenerator
    extends MatcherGenerator<PostfixCharacterClassMatcher> {
  PostfixCharacterClassGenerator(PostfixCharacterClassMatcher matcher)
      : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
