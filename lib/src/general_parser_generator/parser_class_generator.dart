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
    final matcherGenerator = MatcherGeneratorBase(failures: failures!);
    MatcherGenerator accept(Matcher node, MatcherGenerator parent) {
      final generator = node.accept(matcherGenerator);
      generator.allocator = parent.allocator;
      return generator;
    }

    final nameGenerator = ProductionRuleNameGenerator();
    final name = nameGenerator.generate(rule);
    final method = Method((b) {
      if (rule.directCallers.length < 2) {
        final args = [literalString('vm:prefer-inline')];
        final annotation = ref('pragma').call(args);
        b.annotations.add(annotation);
      }

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
      //final generator = ExpressionsGenerator(
      //    failures: failures!, members: members, options: options);
      //final g = expression.accept(generator);
      generator.allocator = allocator;
      generator.generate(block, accept);
      b.body = block.code;
    });

    members.addMethod(name, method);
  }

  void _addRules() {
    for (final rule in grammar.rules) {
      _addRule(rule);
    }
  }
}
