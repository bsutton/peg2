part of '../../parser_generator.dart';

class ProductionRulesGeneratorContext {
  Map<Variable, Variable> aliases = {};

  Map<String, Variable> arguments = {};

  final BlockOperation block;

  Variable result;

  Map<Variable, Variable> savedVariables = {};

  final _utils = OperationUtils();

  ProductionRulesGeneratorContext(this.block);

  Variable addArgument(String name, Variable variable) {
    if (arguments.containsKey(name)) {
      throw StateError('Argument not found: $name');
    }

    arguments[name] = variable;
    return variable;
  }

  Variable addVariable(
      BlockOperation block, VariableAllocator va, Variable variable) {
    var result = aliases[variable];
    if (result != null) {
      return result;
    }

    result = va.newVar(block, 'final', _utils.varOp(variable));
    aliases[variable] = result;
    return result;
  }

  ProductionRulesGeneratorContext copy(BlockOperation block,
      {bool copyAliases = true}) {
    final result = ProductionRulesGeneratorContext(block);
    if (copyAliases) {
      for (final key in aliases.keys) {
        final value = aliases[key];
        result.aliases[key] = value;
      }
    }

    result.arguments = arguments;
    return result;
  }

  Variable getArgument(String name) {
    final result = arguments[name];
    if (result == null) {
      throw StateError('Argument not found: $name');
    }

    return result;
  }

  Variable getAlias(Variable variable) {
    var result = aliases[variable];
    result ??= variable;
    return result;
  }  

  void restoreVariables(BlockOperation block) {
    for (final key in savedVariables.keys) {
      final value = savedVariables[key];
      _utils.addAssign(block, _utils.varOp(key), _utils.varOp(value));
    }
  }

  Variable saveVariable(
      BlockOperation block, VariableAllocator va, Variable variable) {
    if (savedVariables.containsKey(variable)) {
      throw StateError('Variable already saved: ${variable}');
    }

    var result = aliases[variable];
    result ??= va.newVar(block, 'final', _utils.varOp(variable));
    aliases[variable] = result;
    savedVariables[variable] = result;
    return result;
  }
}
