part of '../../matcher_generators.dart';

class PostfixNotPredicateGenerator
    extends PostfixPredicateGenerator<PostfixNotPredicateMatcher> {
  PostfixNotPredicateGenerator(
      PostfixNotPredicateMatcher matcher, BitFlagGenerator failures)
      : super(matcher, failures);
}
