part of '../../matcher_generators.dart';

class PostfixAndPredicateGenerator
    extends PostfixPredicateGenerator<PostfixAndPredicateMatcher> {
  PostfixAndPredicateGenerator(
      PostfixAndPredicateMatcher matcher, BitFlagGenerator failures)
      : super(matcher, failures);
}
