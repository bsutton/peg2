part of '../../matcher_generators.dart';

class PostfixOptionalGenerator
    extends MatcherGenerator<PostfixOptionalMatcher> {
  PostfixOptionalGenerator(PostfixOptionalMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
