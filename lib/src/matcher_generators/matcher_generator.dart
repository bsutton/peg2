part of '../../matcher_generators.dart';

typedef MatcherGeneratorAccept = MatcherGenerator Function(
    Matcher matcher, MatcherGenerator);

class MatcherGenerator<E extends Matcher> {
  VariableAllocator? allocator;

  CodeBlock? fail;

  void Function(CodeBlock block, MatcherGeneratorAccept accept) generate =
      (m, b) => null;

  bool isVariableDeclared = false;

  final E matcher;

  Map<String, String> stored = {};

  CodeBlock? success;

  String? variable;

  Map<String, String> variables = {};

  MatcherGenerator(this.matcher);

  MatcherGenerator acceptChild(MatcherVisitor<MatcherGenerator> visitor,
      Matcher matcher, MatcherGenerator parent) {
    final generator = matcher.accept(visitor);
    generator.allocator = parent.allocator;
    return generator;
  }

  void addVariables(MatcherGenerator other) {
    variables.addAll(other.variables);
  }

  String allocate() {
    return allocator!.allocate();
  }

  String? allocateVariable() {
    if (variable != null) {
      return variable;
    }

    final expression = matcher.expression;
    if (!expression.resultUsed) {
      return null;
    }

    variable = allocator!.allocate();
    return variable;
  }

  String? declareVariable(CodeBlock block, [String? type]) {
    if (isVariableDeclared) {
      return variable;
    }

    final expression = matcher.expression;
    if (!expression.resultUsed) {
      return null;
    }

    isVariableDeclared = true;
    allocateVariable();
    type ??= nullableType(expression.resultType);
    block.declare(variable!, ref(type));
    return variable;
  }

  void generatePostCode(
      MatcherGenerator generator,
      CodeBlock block,
      void Function(CodeBlock block)? success,
      void Function(CodeBlock block)? fail) {
    final successBlock = generator.success;
    final failBlock = generator.fail;
    if (successBlock != null && success != null) {
      success(successBlock);
      success = null;
    }

    if (failBlock != null && fail != null) {
      fail(failBlock);
      fail = null;
    }

    if (success != null || fail != null) {
      final ifElse = IfElseGenerator(ref(Members.ok));
      if (success != null) {
        ifElse.ifCode(success);
      }

      if (fail != null) {
        ifElse.elseCode(fail);
      }

      block.addLazyCode(() => ifElse.generate().code);
    }
  }

  void restore(CodeBlock block, String name) {
    if (!stored.containsKey(name)) {
      throw StateError('Variable has never been stored: $name');
    }

    final variable = stored[name]!;
    block.assign(name, ref(variable));
  }

  void restoreAll(CodeBlock block) {
    for (final name in stored.keys) {
      restore(block, name);
    }
  }

  String store(CodeBlock block, String name) {
    if (stored.containsKey(name)) {
      throw StateError('Variable has already been stored: $name');
    }

    if (variables.containsKey(name)) {
      return variables[name]!;
    }

    final variable = allocator!.allocate();
    stored[name] = variable;
    variables[name] = variable;
    block.assignFinal(variable, ref(name));
    return variable;
  }
}
