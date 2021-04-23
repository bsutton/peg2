part of '../../matcher_generators.dart';

class PostfixSymbolGenerator<E extends PostfixSymbolMatcher>
    extends MatcherGenerator<E> {
  PostfixSymbolGenerator(E matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    // TODO
    throw UnimplementedError();
  }
}
