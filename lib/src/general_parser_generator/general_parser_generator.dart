part of '../../general_parser_generator.dart';

class GeneralParserGenerator extends ParserGenerator {
  GeneralParserGenerator(Grammar grammar, ParserGeneratorOptions options)
      : super(grammar, options);

  @override
  void generateRules(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    final generalProductionRulesGenerator =
        GeneralProductionRulesGenerator(grammar, options);
    generalProductionRulesGenerator.generate(methods, parameters);
  }
}
