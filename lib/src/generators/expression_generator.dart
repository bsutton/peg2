import 'package:peg2/expressions.dart';
import 'package:peg2/src/generators/variable_allocator.dart';
import 'package:peg2/src/helpers/expression_helper.dart';
import 'package:peg2/src/helpers/type_helper.dart';

import 'code_block.dart';

class ExpressionGenerator {
  VariableAllocator? allocator;

  final Expression expression;

  CodeBlock? fail;

  void Function(CodeBlock block) generate = (block) => null;

  bool isVariableDeclared = false;

  Map<String, String> stored = {};

  CodeBlock? success;

  String? variable;

  Map<String, String> variables = {};

  ExpressionGenerator(this.expression);

  void addVariables(ExpressionGenerator other) {
    variables.addAll(other.variables);
  }

  String allocate() {
    return allocator!.allocate();
  }

  String? allocateVariable() {
    if (variable != null) {
      return variable;
    }

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

    if (!expression.resultUsed) {
      return null;
    }

    isVariableDeclared = true;
    allocateVariable();
    type ??= nullableType(expression.resultType);
    block.declare(variable!, ref(type));
    return variable;
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
