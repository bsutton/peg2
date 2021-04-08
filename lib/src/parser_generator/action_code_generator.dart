// @dart = 2.10
part of '../../parser_generator.dart';

class ActionCodeGenerator {
  final List<Code> code;

  final SequenceExpression sequence;

  final String variable;

  final List<String> variables;

  ActionCodeGenerator(
      {@required this.code,
      @required this.sequence,
      @required this.variable,
      @required this.variables});

  void generate() {
    if (sequence.actionIndex != null) {
      _genearteActionCode();
    } else {
      _generateResultCode();
    }
  }

  void _error() {
    final sink = StringBuffer();
    sink.writeln('Error generating result return code.');
    sink.write('Expression: $sequence');
    throw StateError(sink.toString());
  }

  void _genearteActionCode() {
    final expressions = sequence.expressions;
    final sink = StringBuffer();
    for (var i = 0; i < expressions.length; i++) {
      final expression = expressions[i];
      final left = expression.variable;
      if (left == null) {
        continue;
      }

      final right = variables[i];
      if (right == null) {
        _error();
      }

      sink.write('final ');
      sink.write(left);
      sink.write(' = ');
      sink.write(expression.nullCheckedValue(right));
      sink.write(';');
    }

    final returnType = sequence.returnType;
    if (_isDynamicType(returnType)) {
      sink.write('var ');
    } else {
      sink.write('late ');
      sink.write(sequence.returnType);
    }

    sink.write(' \$\$;');
    sink.write(sequence.actionSource);
    if (variable != null) {
      sink.write(variable);
      sink.write(' = \$\$;');
    }

    code << Code(sink.toString());
  }

  void _generateResultCode() {
    if (variable == null) {
      _error();
    }

    final right = _getDefaultResult();
    final sink = StringBuffer();
    sink.write(variable);
    sink.write(' = ');
    sink.write(right);
    sink.write(';');
    code << Code(sink.toString());
  }

  String _getDefaultResult() {
    final expressions = sequence.expressions;
    final semantic = expressions.where((e) => e.variable != null).toList();
    String right;
    if (expressions.length == 1) {
      right = variables[0];
    } else {
      if (semantic.isEmpty) {
        right = variables[0];
      } else if (semantic.length == 1) {
        final index = semantic[0].index;
        right = variables[index];
      } else {
        final list = <String>[];
        var success = true;
        for (var i = 0; i < expressions.length; i++) {
          final expression = expressions[i];
          if (expression.variable != null) {
            final variable = variables[i];
            if (variable == null) {
              success = false;
              break;
            }
          }
        }

        if (success) {
          right = list.join(', ');
          right = '[$right]';
        }
      }
    }

    if (right == null) {
      _error();
    }

    return right;
  }

  bool _isDynamicType(String type) {
    return type == 'dynamic' || type == 'dynamic?';
  }
}
