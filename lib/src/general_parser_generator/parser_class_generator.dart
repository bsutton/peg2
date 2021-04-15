// @dart = 2.10
part of '../../general_parser_generator.dart';

class ParserClassGenerator extends ParserClassGeneratorBase {
  ParserClassGenerator(
      String name, Grammar grammar, ParserGeneratorOptions options)
      : super(name, grammar, options);

  @override
  void addMembers(ClassBuilder builder) {
    _addRules();
  }

  void _addRule(ProductionRule rule) {
    final name = IdentifierHelper.getRuleIdentifier(rule);
    final method = Method((b) {
      if (rule.directCallers.length < 2) {
        b.annotations
            .add(refer('pragma').call([literalString('vm:prefer-inline')]));
      }

      b.name = name;
      final expression = rule.expression;
      final returnType = rule.returnType ?? expression.resultType;
      final returns = Utils.getNullableType(returnType);
      b.returns = refer(returns);
      final allocator = VariableAllocator('\$');
      final code = <Code>[];
      final generator = ExpressionsGenerator(
          allocator: allocator,
          code: code,
          failures: failures,
          members: members,
          optimize: options.optimize);
      expression.accept(generator);
      b.body = Block.of(code);
    });

    members.addMethod(name, method);
  }

  void _addRules() {
    for (final rule in grammar.rules) {
      _addRule(rule);
    }
  }
}
