part of '../../postfix_parser_generator.dart';

class PostfixProductionRulesGenerator
    with
        OperationUtils,
        PostfixProductionRuleUtils,
        ProductionRuleUtils,
        ProductionRulesGenerator {
  final Grammar grammar;

  final ParserGeneratorOptions options;

  Set<ProductionRule> _calledRules;

  Map<SequenceExpression, MethodOperation> _methods;

  PostfixProductionRulesGenerator(this.grammar, this.options);

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    _calledRules = {};
    _methods = {};
    final start = grammar.start;
    _calledRules.add(start);
    final generated = <ProductionRule>{};
    var success = true;
    while (success) {
      success = false;
      for (final rule in _calledRules) {
        if (generated.add(rule)) {
          success = true;
          final method = _generateRule(rule);
          methods.add(method);
          break;
        }
      }
    }

    methods.addAll(_methods.values);
  }

  MethodOperation _generateRule(ProductionRule rule) {
    final va = newVarAlloc();
    final block = BlockOperation();
    final expression = rule.expression;
    final callerId = va.alloc(true);
    final productive = va.alloc(true);
    final name = getMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', callerId));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= expression.returnType;
    final generator = PostfixExpressionOperationGenerator(options, block, va);
    generator.callerId = callerId;
    generator.productive = productive;
    generator.mode = 1;
    expression.accept(generator);
    _methods.addAll(generator._methods);
    addReturn(block, varOp(generator.result));
    final result = MethodOperation(returnType, name, params, block);
    _calledRules.addAll(generator.calledRules);
    return result;
  }
}
