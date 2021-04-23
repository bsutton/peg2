part of '../../matcher_generators.dart';

class PostfixCaptureGenerator extends MatcherGenerator<PostfixCaptureMatcher> {
  PostfixCaptureGenerator(PostfixCaptureMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
