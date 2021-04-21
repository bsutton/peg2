import '..//helpers/null_check_helper.dart';
import '../helpers/expression_helper.dart';
import '../helpers/type_helper.dart';
import 'code_block.dart';

class ActionCodeGenerator {
  final String? actionSource;

  CodeBlock block;

  final List<String?> localVariables;

  final List<String?> semanticVariables;

  String resultType;

  final List<String> types;

  String? variable;

  ActionCodeGenerator(
      {required this.actionSource,
      required this.block,
      required this.localVariables,
      required this.semanticVariables,
      required this.resultType,
      required this.types,
      required this.variable});

  void generate(List<String> errors) {
    if (actionSource != null) {
      _genearteActionCode(errors);
    } else {
      _generateResultCode(errors);
    }
  }

  void _assignSemanticVariables(List<String> errors) {
    for (var i = 0; i < semanticVariables.length; i++) {
      final semanticVariable = semanticVariables[i];
      if (semanticVariable == null) {
        continue;
      }

      final localVariable = localVariables[i];
      if (localVariable == null) {
        errors.add(
            'No local variable specified for the semantic variable \'$semanticVariable\'');
        return;
      }

      final type = types[i];
      final value = nullCheck(ref(localVariable), type);
      block.assignFinal(semanticVariable, value);
    }
  }

  void _genearteActionCode(List<String> errors) {
    _assignSemanticVariables(errors);
    final type = nullableType(resultType);
    block.declare('\$\$', ref(type));
    block.addSourceCode(actionSource!);
    if (variable != null) {
      block.assign(variable!, ref('\$\$'));
    }
  }

  void _generateResultCode(List<String> errors) {
    if (variable == null) {
      errors.add('A local variable was not specified to assign the result');
      return;
    }

    if (semanticVariables.isEmpty) {
      errors.add('No variables are specified to assign the result');
      return;
    }

    _assignSemanticVariables(errors);
    final values = <String>[];
    for (var i = 0; i < semanticVariables.length; i++) {
      final semanticVariable = semanticVariables[i];
      if (semanticVariable != null) {
        values.add(semanticVariable);
      }
    }

    if (values.isEmpty) {
      //final value = localVariables.first;
      //values.add(value);
    }

    if (values.length == 1) {
      block.assign(variable!, ref(values.first));
    } else if (values.length > 1) {
      final list = literalList(values.map(ref));
      block.assign(variable!, list);
    }
  }
}
