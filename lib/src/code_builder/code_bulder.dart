part of '../../code_builder.dart';

class BlockStatementBuilder extends StatementBuilder {
  BlockStatementBuilder() : super();
}

abstract class Builder {
  List<String> build(int row);

  String indent(String s, int length) {
    return ''.padRight(length, ' ') + s;
  }
}

class ClassBuilder extends ContentBuilder {
  final bool isAbstract;

  final String inheritance;

  final String name;

  ClassBuilder({this.isAbstract = false, this.inheritance, this.name}) {
    if (isAbstract == null) {
      throw ArgumentError.notNull('isAbstract');
    }

    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('Argument "name" must not be empty');
    }
  }

  @override
  List<String> build(int row) {
    final result = <String>[];
    final sb = StringBuffer();
    if (isAbstract) {
      sb.write('abstract ');
    }

    sb.write('class ');
    sb.write(name);
    sb.write(' ');
    if (inheritance != null) {
      sb.write(inheritance);
      sb.write(' ');
    }

    sb.write('{');
    result.add(indent(sb.toString(), row));
    result.addAll(super.build(row + 2));
    result.add(indent('}', row));
    result.add(indent('', row));
    return result;
  }
}

class ContentBuilder<T> extends Builder {
  final content = <T>[];

  void add(T element) {
    content.add(element);
  }

  void addAll(Iterable<T> elements) {
    content.addAll(elements);
  }

  @override
  List<String> build(int row) {
    final result = <String>[];
    for (final element in content) {
      if (element is Builder) {
        final lines = element.build(row);
        result.addAll(lines);
      } else if (element is String) {
        final line = indent('$element', row);
        result.add(line);
      }
    }

    return result;
  }
}

class ForStatementBuilder extends StatementBuilder {
  ForStatementBuilder(String condition)
      : super(preName: 'for', preArgs: condition);
}

class IfStatementBuilder extends _IfStatementBuilder {
  IfStatementBuilder(String condition) : super('if', condition);
}

class MethodBuilder extends ContentBuilder {
  final String modifier;

  final String name;

  final String parameters;

  final String returnType;

  MethodBuilder({this.modifier, this.name, this.parameters, this.returnType}) {
    if (name == null) {
      throw ArgumentError.notNull('name');
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('Argument "name" must not be empty');
    }
  }

  @override
  List<String> build(int row) {
    final result = <String>[];
    final sb = StringBuffer();
    if (returnType != null) {
      sb.write(returnType);
      sb.write(' ');
    }

    sb.write(name);
    sb.write('(');
    if (parameters != null) {
      sb.write(parameters);
    }

    sb.write(') ');
    if (modifier != null) {
      sb.write(modifier);
      sb.write(' ');
    }

    sb.write('{');
    result.add(indent(sb.toString(), row));
    result.addAll(super.build(row + 2));
    result.add(indent('}', row));
    result.add(indent('', row));
    return result;
  }
}

abstract class StatementBuilder extends ContentBuilder {
  final String preArgs;

  final String preName;

  final String postArgs;

  final String postName;

  StatementBuilder({this.preArgs, this.preName, this.postArgs, this.postName});

  @override
  List<String> build(int row) {
    final result = <String>[];
    final sb = StringBuffer();
    if (preName != null) {
      sb.write(preName);
      sb.write(' ');
    }

    if (preArgs != null) {
      sb.write('(');
      sb.write(preArgs);
      sb.write(') ');
    }

    sb.write('{');
    result.add(indent(sb.toString(), row));
    for (final element in content) {
      if (element is Builder) {
        final lines = element.build(row + 2);
        result.addAll(lines);
      } else if (element is String) {
        final line = indent('$element', row + 2);
        result.add(line);
      }
    }

    sb.clear();
    sb.write('}');
    if (postName != null) {
      sb.write(' ');
      sb.write(postName);
      sb.write(' ');
    }

    if (postArgs != null) {
      sb.write('(');
      sb.write(postArgs);
      sb.write(')');
    }

    result.add(indent(sb.toString(), row));
    return result;
  }
}

class WhileStatementBuilder extends StatementBuilder {
  WhileStatementBuilder(String condition)
      : super(preName: 'while', preArgs: condition);
}

class _ElseIfStatementBuilder extends _IfStatementBuilder {
  _ElseIfStatementBuilder(String condition) : super('else if', condition);
}

class _ElseStatementBuilder extends StatementBuilder {
  _ElseStatementBuilder() : super(preName: 'else');
}

class _IfStatementBuilder extends StatementBuilder {
  StatementBuilder _next;

  _IfStatementBuilder(String name, String condition)
      : super(preName: name, preArgs: condition) {
    if (condition == null) {
      throw ArgumentError.notNull('condition');
    }
  }

  _ElseStatementBuilder addElse() {
    if (_next != null) {
      throw StateError('Unable to add "else" statement');
    }

    _next = _ElseStatementBuilder();
    return _next as _ElseStatementBuilder;
  }

  _ElseIfStatementBuilder addElseIf(String condition) {
    if (_next != null) {
      throw StateError('Unable to add "else if" statement');
    }

    _next = _ElseIfStatementBuilder(condition);
    return _next as _ElseIfStatementBuilder;
  }

  @override
  List<String> build(int row) {
    final result = super.build(row);
    if (_next != null) {
      final lines = _next.build(row);
      result.last += ' ' + lines.first.trimLeft();
      lines.removeAt(0);
      result.addAll(lines);
    }

    return result;
  }
}
