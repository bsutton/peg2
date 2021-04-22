part of '../../matcher_generators.dart';

class SequenceGenerator extends MatcherGenerator<SequenceMatcher> {
  SequenceGenerator(SequenceMatcher matcher) : super(matcher) {
    generate = _generate;
  }

  void _generate(CodeBlock block, MatcherGeneratorAccept accept) {
    declareVariable(block);
    final matchers = matcher.matchers;
    final expression = matcher.expression;
    final expressions = expression.expressions;
    final localVariables = <String?>[];
    final semanticVariables = <String?>[];
    final types = <String>[];
    final generators = <MatcherGenerator>[];
    final active = expressions.where((e) => e.variable != null);
    var activeIndex = -1;
    if (expression.actionSource == null) {
      if (active.isEmpty) {
        activeIndex = 0;
      } else if (active.length == 1) {
        activeIndex = active.first.index!;
      }
    }

    var succesBlock = block;
    for (var i = 0; i < matchers.length; i++) {
      final child = matchers[i];
      final generator = accept(child, this);
      generators.add(generator);
      if (i == 0) {
        generator.addVariables(this);
      }

      if (i == activeIndex) {
        if (child.resultUsed) {
          generator.variable = variable;
          generator.isVariableDeclared = isVariableDeclared;
        }
      }

      if (i > 0 && !expressions[i - 1].isOptional) {
        succesBlock.if$(ref(Members.ok), (block) {
          succesBlock = block;
          generator.generate(block, accept);
        });
      } else {
        generator.generate(succesBlock, accept);
      }

      localVariables.add(generator.variable);
      semanticVariables.add(child.expression.variable);
      types.add(child.resultType);
    }

    _generateSequenceAction(succesBlock,
        localVariables: localVariables,
        semanticVariables: semanticVariables,
        types: types);
  }

  void _generateSequenceAction(CodeBlock block,
      {required List<String?> localVariables,
      required List<String?> semanticVariables,
      required List<String> types}) {
    final node = matcher.expression;
    final expressions = node.expressions;
    if (variable != null || node.actionIndex != null) {
      final errors = <String>[];
      void action(CodeBlock block) {
        final actionCodeGenerator = ActionCodeGenerator(
          block: block,
          actionSource: node.actionSource,
          localVariables: localVariables,
          resultType: node.resultType,
          semanticVariables: semanticVariables,
          types: types,
          variable: variable,
        );
        actionCodeGenerator.generate(errors);
        if (errors.isNotEmpty) {
          final message = 'Error generating result for expression: $node';
          throw StateError(message);
        }
      }

      if (expressions.last.isOptional) {
        action(block);
        success = block;
      } else {
        final ifElse = IfElseGenerator(ref(Members.ok));
        ifElse.ifCode(action);
        block.addLazyCode(() => ifElse.generate().code);
        //block.if$(ref(Members.ok), (block) {
        //  action(block);
        //  generator.success = block;
        //});
      }
    }
  }
}
