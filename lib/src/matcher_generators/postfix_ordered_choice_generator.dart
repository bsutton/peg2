part of '../../matcher_generators.dart';

class PostfixOrderedChoiceGenerator
    extends MatcherGenerator<PostfixOrderedChoiceMatcher> {
  PostfixOrderedChoiceGenerator(PostfixOrderedChoiceMatcher matcher)
      : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
