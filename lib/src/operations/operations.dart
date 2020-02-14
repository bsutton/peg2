part of '../../operations.dart';

class ActionOperation extends Operation {
  List<Operation> arguments;

  List<String> code;

  ActionOperation(this.arguments, this.code);

  @override
  OperationKind get kind => OperationKind.action;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitActionOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    for (final argument in arguments) {
      argument.accept(visitor);
    }
  }
}

class BinaryOperation extends Operation {
  @override
  final OperationKind kind;

  Operation left;

  Operation right;

  BinaryOperation(this.left, this.kind, this.right) {
    switch (kind) {
      case OperationKind.assign:
        break;
      default:
        _errorInvalidOpertionKin();
    }
  }

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitBinaryOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }
}

class BlockOperation extends Operation {
  List<Operation> operations = [];

  BlockOperation([List<Operation> operations]) {
    if (operations != null) {
      this.operations.addAll(operations);
    }
  }

  @override
  OperationKind get kind => OperationKind.block;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitBlockOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    for (final operation in operations) {
      operation.accept(visitor);
    }
  }
}

class BreakOperation extends Operation {
  @override
  OperationKind get kind => OperationKind.break_;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitBreakOperation(this);
  }
}

class CallOperation extends Operation {
  List<Operation> arguments;

  Operation function;

  CallOperation(this.function, this.arguments);

  @override
  OperationKind get kind => OperationKind.call;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitCallOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    function.accept(visitor);
    for (final argument in arguments) {
      argument.accept(visitor);
    }
  }
}

class ConditionalOperation extends Operation {
  BlockOperation ifFalse;

  BlockOperation ifTrue;

  Operation test;

  ConditionalOperation(this.test, this.ifTrue, [this.ifFalse]);

  @override
  OperationKind get kind => OperationKind.conditional;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitConditionalOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    test.accept(visitor);
    ifTrue.accept(visitor);
    ifFalse?.accept(visitor);
  }
}

class ConstantOperation<T> extends Operation {
  T value;

  ConstantOperation(this.value);

  @override
  OperationKind get kind => OperationKind.constant;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitConstantOperation(this);
  }
}

class ListOperation extends Operation {
  String type;

  List<Operation> elements;

  ListOperation(this.type, this.elements);

  @override
  OperationKind get kind => OperationKind.list;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitListOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    for (final element in elements) {
      element.accept(visitor);
    }
  }
}

class LoopOperation extends Operation {
  BlockOperation body;

  LoopOperation([this.body]) {
    body ??= BlockOperation();
  }

  @override
  OperationKind get kind => OperationKind.loop;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitLoopOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    body.accept(visitor);
  }
}

class MemberOperation extends Operation {
  Operation member;

  Operation operation;

  MemberOperation(this.member, this.operation);

  @override
  OperationKind get kind => OperationKind.method;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitMemberOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    member.accept(visitor);
    operation.accept(visitor);
  }
}

class MethodOperation extends Operation {
  BlockOperation body;

  String name;

  String returnType;

  List<ParameterOperation> parameters;

  MethodOperation(this.returnType, this.name, this.parameters, [this.body]) {
    body ??= BlockOperation();
  }

  @override
  OperationKind get kind => OperationKind.method;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitMethodOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    for (final parameter in parameters) {
      parameter.accept(visitor);
    }

    body.accept(visitor);
  }
}

class NopOperation extends Operation {
  @override
  OperationKind get kind => OperationKind.nop;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitNopOperation(this);
  }
}

abstract class Operation {
  Operation parent;

  Map<Variable, int> readings = {};

  Map<Variable, Operation> variableResults = {};

  Map<Variable, int> writings = {};

  OperationKind get kind;

  void accept(OperationVisitor visitor);

  void variableUsage(Variable variable, int count, VariableUsage usage) {
    Map<Variable, int> stat;
    if (usage == VariableUsage.read) {
      stat = readings;
    } else if (usage == VariableUsage.write) {
      stat = writings;
    } else {
      throw StateError('Unknown variable usage kind: $usage');
    }

    if (stat[variable] == null) {
      stat[variable] = 0;
    }

    stat[variable] += count;
    if (parent != null) {
      parent.variableUsage(variable, count, usage);
    }
  }

  void visitChildren(OperationVisitor visitor) {
    //
  }

  void _errorInvalidOpertionKin() {
    throw StateError('Invalid opertion kind: $kind');
  }
}

enum OperationKind {
  action,
  assign,
  block,
  binary,
  break_,
  call,
  conditional,
  constant,
  list,
  loop,
  method,
  nop,
  not,
  parameter,
  return_,
  variable,
}

class ParameterOperation extends Operation {
  Operation operation;

  String type;

  Variable variable;

  ParameterOperation(this.type, this.variable, [this.operation]);

  @override
  OperationKind get kind => OperationKind.parameter;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitParameterOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    operation?.accept(visitor);
  }
}

class ReturnOperation extends Operation {
  Operation operation;

  ReturnOperation([this.operation]);

  @override
  OperationKind get kind => OperationKind.return_;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitReturnOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    operation?.accept(visitor);
  }
}

class UnaryOperation extends Operation {
  @override
  final OperationKind kind;

  Operation operand;

  UnaryOperation(this.kind, this.operand) {
    switch (kind) {
      case OperationKind.not:
        break;
      default:
        _errorInvalidOpertionKin();
    }
  }

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitUnaryOperation(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    operand.accept(visitor);
  }
}

class Variable {
  String name;

  Variable(this.name);
}

class VariableOperation extends Operation {
  Variable variable;

  VariableOperation(this.variable);

  @override
  OperationKind get kind => OperationKind.variable;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitVariableOperation(this);
  }
}

enum VariableUsage { read, write }
