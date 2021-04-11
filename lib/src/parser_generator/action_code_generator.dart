// @dart = 2.10
part of '../../parser_generator.dart';

class ActionCodeGenerator {
  final String actionSource;

  final List<Code> code;

  final List<String> localVariables;

  final List<String> semanticVariables;

  String resultType;

  final List<String> types;

  String variable;

  ActionCodeGenerator(
      {@required this.actionSource,
      @required this.code,
      @required this.localVariables,
      @required this.semanticVariables,
      @required this.resultType,
      @required this.types,
      @required this.variable});

  void generate(List<String> errors) {
    if (actionSource != null) {
      _genearteActionCode(errors);
    } else {
      _generateResultCode(errors);
    }
  }

  void _assignSemanticVariables(StringSink sink, List<String> errors) {
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
      if (type == null) {
        errors.add(
            'The value type is not specified for the semantic variable \'$semanticVariable\'');
        return;
      }

      final value = Utils.getNullCheckedValue(localVariable, type);
      sink.write('final ');
      sink.write(semanticVariable);
      sink.write(' = ');
      sink.write(value);
      sink.write(';');
    }
  }

  void _genearteActionCode(List<String> errors) {
    final sink = StringBuffer();
    _assignSemanticVariables(sink, errors);
    if (Utils.isDynamicType(resultType)) {
      sink.write('var ');
    } else {
      sink.write('late ');
      sink.write(resultType);
    }

    sink.write(' \$\$;');
    sink.write(actionSource);
    if (variable != null) {
      sink.write(variable);
      sink.write(' = \$\$;');
    }

    code << Code(sink.toString());
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

    final sink = StringBuffer();
    _assignSemanticVariables(sink, errors);
    final values = <String>[];
    for (var i = 0; i < semanticVariables.length; i++) {
      final semanticVariable = semanticVariables[i];
      if (semanticVariable != null) {
        values.add(semanticVariable);
      }
    }

    if (values.isEmpty) {
      final value = localVariables.first;
      values.add(value);
    }

    final value =
        values.length == 1 ? values.first : '[' + values.join(', ') + ']';

    sink.write(variable);
    sink.write(' = ');
    sink.write(value);
    sink.write(';');
    code << Code(sink.toString());
  }
}
