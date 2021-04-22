part of '../../matcher_generators.dart';

class AndPredicateGenerator extends PredicateGenerator<AndPredicateMatcher> {
  AndPredicateGenerator(AndPredicateMatcher matcher, BitFlagGenerator failures)
      : super(matcher, failures);
}
