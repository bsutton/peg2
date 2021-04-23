part of '../../matcher_generators.dart';

class PostfixZeroOrMoreGenerator
    extends MatcherGenerator<PostfixZeroOrMoreMatcher> {
  PostfixZeroOrMoreGenerator(PostfixZeroOrMoreMatcher matcher)
      : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
