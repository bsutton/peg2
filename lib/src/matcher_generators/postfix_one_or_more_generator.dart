part of '../../matcher_generators.dart';

class PostfixOneOrMoreGenerator
    extends MatcherGenerator<PostfixOneOrMoreMatcher> {
  PostfixOneOrMoreGenerator(PostfixOneOrMoreMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
