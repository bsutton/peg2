part of '../../matcher_generators.dart';

abstract class PostfixPredicateGenerator<E extends PostfixPredicateMatcher>
    extends MatcherGenerator<E> {
  final BitFlagGenerator failures;

  PostfixPredicateGenerator(E matcher, this.failures) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
