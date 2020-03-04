part of '../../parser_generator.dart';

abstract class ProductionRulesGenerator {
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters);
}
