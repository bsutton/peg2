part of '../../postfix_parser_generator.dart';

class PostfixProductionRulesGenerator
    with
        OperationUtils,
        PostfixProductionRuleUtils,
        ProductionRuleUtils,
        ProductionRulesGenerator {
  final Grammar grammar;

  final ParserGeneratorOptions options;

  Map<SequenceExpression, MethodOperation> _methods;

  PostfixProductionRulesGenerator(this.grammar, this.options);

  @override
  void generate(
      List<MethodOperation> methods, List<ParameterOperation> parameters) {
    _methods = {};
    final rules = grammar.rules;
    for (final rule in rules) {
      final method = _generateRule(rule);
      methods.add(method);
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
    final generator = PostfixExpressionOperationGenerator0(options, block, va);
    generator.callerId = callerId;
    generator.productive = productive;
    expression.accept(generator);
    addReturn(block, varOp(generator.result));
    final result = MethodOperation(returnType, name, params, block);
    return result;
  }
}
