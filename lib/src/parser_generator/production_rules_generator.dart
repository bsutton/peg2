part of '../../parser_generator.dart';

abstract class ProductionRulesGenerator {
  final List<ProductionRulesGeneratorContext> contexts = [];

  final Grammar grammar;

  final ParserGeneratorOptions options;

  ProductionRulesGenerator(this.grammar, this.options);

  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters);
}
