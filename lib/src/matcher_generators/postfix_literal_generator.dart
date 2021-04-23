part of '../../matcher_generators.dart';

class PostfixLiteralGenerator extends MatcherGenerator<PostfixLiteralMatcher> {
  PostfixLiteralGenerator(PostfixLiteralMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
