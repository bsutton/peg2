part of '../../postfix_parser_generator.dart';

class PostfixParserGenerator extends ParserGenerator {
  PostfixParserGenerator(Grammar grammar, ParserGeneratorOptions options)
      : super(grammar, options);

  @override
  void generateRules(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    final postfixProductionRulesGenerator =
        PostfixProductionRulesGenerator(grammar, options);
    postfixProductionRulesGenerator.generate(methods, parameters);
  }
}
