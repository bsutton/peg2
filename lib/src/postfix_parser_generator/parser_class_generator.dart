part of '../../postfix_parser_generator.dart';

class ParserClassGenerator extends ParserClassGeneratorBase {
  ParserClassGenerator(
      String name, Grammar grammar, ParserGeneratorOptions options)
      : super(name, grammar, options);

  @override
  void addMembers(ClassBuilder builder) {
    _addRules();
  }

  void _addRule(ProductionRule rule) {
    final matcherGenerator = MatcherGeneratorBase(failures: failures!);
    MatcherGenerator accept(Matcher node, MatcherGenerator parent) {
      final generator = node.accept(matcherGenerator);
      generator.allocator = parent.allocator;
      return generator;
    }

    final nameGenerator = ProductionRuleNameGenerator();
    final name = nameGenerator.generate(rule);
    var returnType = rule.returnType ?? rule.expression.resultType;
    returnType = nullableType(returnType);
    final method = Method((b) {
      b.name = name;
      final expression = rule.expression;
      final returnType = rule.returnType ?? expression.resultType;
      final returns = nullableType(returnType);
      b.returns = ref(returns);
      final block = CodeBlock();
      final allocator = VariableAllocator('\$');
      final converter = ExpressionsToMatchersConverter();
      final matcher = expression.accept(converter);
      final generator = matcher.accept(matcherGenerator);
      generator.allocator = allocator;
      generator.generate(block, accept);
      b.body = block.code;
    });

    members.addMethod(name, method);
  }

  void _addRules() {
    final rules = grammar.rules;
    for (final rule in rules) {
      _addRule(rule);
    }
  }
}
