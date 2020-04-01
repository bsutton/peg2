part of '../../general_parser_generator.dart';

class GeneralProductionRulesGenerator
    with OperationUtils, ProductionRulesGenerator, ProductionRuleUtils {
  final Grammar grammar;

  final ParserGeneratorOptions options;

  GeneralProductionRulesGenerator(this.grammar, this.options);

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    final rules = grammar.rules;
    for (final rule in rules) {
      var skip = false;
      final willInline = needToInline(rule, options);
      if (willInline) {
        switch (rule.kind) {
          case ProductionRuleKind.nonterminal:
            if (options.inlineNonterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.subterminal:
            if (options.inlineSubterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.terminal:
            if (options.inlineTerminals) {
              skip = true;
            }

            break;
          default:
        }
      }

      if (!skip) {
        final method = _generateRule(rule);
        methods.add(method);
      }
    }
  }

  MethodOperation _generateRule(ProductionRule rule) {
    final va = newVarAlloc();
    final block = BlockOperation();
    final expression = rule.expression;
    final memoize = va.alloc(true);
    final productive = va.alloc(true);
    final productionRuleNameGenerator = ProductionRuleNameGenerator();
    final name = productionRuleNameGenerator.generate(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('bool', memoize));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;
    final generator = GeneralExpressionOperationGenerator(options, block, va);
    generator.memoize = memoize;
    generator.productive = productive;
    expression.accept(generator);
    final result = MethodOperation(returnType, name, params, block);
    return result;
  }
}
