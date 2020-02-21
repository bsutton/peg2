part of '../../generators.dart';

class OperationsToCodeConverter extends OperationVisitor {
  dynamic _result;

  ContentBuilder convert(List<MethodOperation> methods) {
    final builder = ContentBuilder();
    for (final method in methods) {
      method.accept(this);
      builder.add(_result);
    }

    return builder;
  }

  @override
  void visitActionOperation(ActionOperation node) {
    final builder = ContentBuilder();
    builder.addAll(node.code);
    _result = builder;
  }

  @override
  void visitBinaryOperation(BinaryOperation node) {
    final sb = StringBuffer();
    node.left.accept(this);
    sb.write(_resultAsString());
    sb.write(' ');
    switch (node.kind) {
      case OperationKind.assign:
        sb.write('=');
        break;
      case OperationKind.equal:
        sb.write('==');
        break;
      default:
        throw StateError('Unknown binary operation: ${node.kind}');
    }

    sb.write(' ');
    node.right.accept(this);
    sb.write(_resultAsString());
    _result = sb.toString();
  }

  @override
  void visitBlockOperation(BlockOperation node) {
    final builder = BlockStatementBuilder();
    for (final operation in node.operations) {
      operation.accept(this);
      if (_result is String) {
        if ((_result as String).isNotEmpty) {
          builder.add(_result + ';');
        }
      } else if (_result is Builder) {
        builder.add(_result);
      } else {
        throw StateError('Unknown result: $_result');
      }
    }

    _result = builder;
  }

  @override
  void visitBreakOperation(BreakOperation node) {
    _result = 'break';
  }

  @override
  void visitCallOperation(CallOperation node) {
    final sb = StringBuffer();
    node.function.accept(this);
    sb.write(_resultAsString());
    sb.write('(');
    final arguments = <String>[];
    for (var argument in node.arguments) {
      argument.accept(this);
      arguments.add(_resultAsString());
    }

    sb.write(arguments.join(', '));
    sb.write(')');
    _result = sb.toString();
  }

  @override
  void visitConditionalOperation(ConditionalOperation node) {
    node.test.accept(this);
    final test = _resultAsString();
    final builder = IfStatementBuilder(test);
    node.ifTrue.accept(this);
    builder.addAll(_resultAsContent());
    if (node.ifFalse != null) {
      final elseBuilder = builder.addElse();
      node.ifFalse.accept(this);
      elseBuilder.addAll(_resultAsContent());
    }

    _result = builder;
  }

  @override
  void visitConstantOperation(ConstantOperation node) {
    final value = node.value;
    if (value is String) {
      _result = '\'${Utils.escape(value)}\'';
    } else if (value is bool || value is num) {
      _result = node.value.toString();
    } else if (value == null) {
      _result = 'null';
    } else {
      throw StateError('Unsupported constant: ${value.runtimeType}');
    }
  }

  @override
  void visitListAccessOperation(ListAccessOperation node) {
    final sb = StringBuffer();
    node.list.accept(this);
    sb.write(_resultAsString());
    sb.write('[');
    node.index.accept(this);
    sb.write(_resultAsString());
    sb.write(']');
    _result = sb.toString();
  }

  @override
  void visitListOperation(ListOperation node) {
    final list = <String>[];
    for (final element in node.elements) {
      element.accept(this);
      list.add(_resultAsString());
    }

    final sb = StringBuffer();
    if (node.type != null) {
      sb.write(node.type);
      sb.write(' ');
    }

    sb.write('[');
    sb.write(list.join(', '));
    sb.write(']');
    _result = sb.toString();
  }

  @override
  void visitLoopOperation(LoopOperation node) {
    final builder = ForStatementBuilder(';;');
    node.body.accept(this);
    builder.addAll(_resultAsContent());
    _result = builder;
  }

  @override
  void visitMemberOperation(MemberOperation node) {
    final sb = StringBuffer();
    node.owner.accept(this);
    sb.write(_resultAsString());
    sb.write('.');
    node.member.accept(this);
    sb.write(_resultAsString());
    _result = sb.toString();
  }

  @override
  void visitMethodOperation(MethodOperation node) {
    final type = node.returnType.toString();
    final name = node.name.toString();
    final parameters = <String>[];
    for (final param in node.parameters) {
      param.accept(this);
      parameters.add(_resultAsString());
    }

    final builder = MethodBuilder(
        name: name, parameters: parameters.join(', '), returnType: type);
    node.body.accept(this);
    builder.addAll(_resultAsContent());
    _result = builder;
  }

  @override
  void visitNopOperation(NopOperation node) {
    _result = '// NOP';
  }

  @override
  void visitParameterOperation(ParameterOperation node) {
    final sb = StringBuffer();
    sb.write(node.type);
    sb.write(' ');
    sb.write(node.variable.name);
    if (node.operation != null) {
      node.operation.accept(this);
      sb.write(' = ');
      sb.write(_resultAsString());
    }

    _result = sb.toString();
  }

  @override
  void visitReturnOperation(ReturnOperation node) {
    final sb = StringBuffer();
    sb.write('return');
    if (node.operation != null) {
      node.operation.accept(this);
      sb.write(' ');
      sb.write(_result);
    }

    _result = sb.toString();
  }

  @override
  void visitUnaryOperation(UnaryOperation node) {
    final sb = StringBuffer();
    switch (node.kind) {
      case OperationKind.not:
        sb.write('!');
        node.operand.accept(this);
        sb.write(_resultAsString());
        break;
      case OperationKind.convert:
        node.operand.accept(this);
        sb.write(_resultAsString());
        sb.write(' as ');
        sb.write(node.type);
        break;
      default:
        throw StateError('Unknown unary operation: ${node.kind}');
    }

    _result = sb.toString();
  }

  @override
  void visitVariableOperation(VariableOperation node) {
    _result = node.variable.name.toString();
  }

  List _resultAsContent() {
    if (_result is ContentBuilder) {
      final builder = _result as ContentBuilder;
      return builder.content;
    }

    throw StateError('Expected "${ContentBuilder}" result');
  }

  String _resultAsString() {
    if (_result is String) {
      return _result as String;
    }

    throw StateError('Expected "Builder" result');
  }
}
