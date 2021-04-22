part of '../../matcher_generators.dart';

class NotPredicateGenerator extends PredicateGenerator<NotPredicateMatcher> {
  NotPredicateGenerator(NotPredicateMatcher matcher, BitFlagGenerator failures)
      : super(matcher, failures);
}
