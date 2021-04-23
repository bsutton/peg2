part of '../../matcher_generators.dart';

class PostfixSequenceGenerator
    extends MatcherGenerator<PostfixSequenceMatcher> {
  PostfixSequenceGenerator(PostfixSequenceMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
