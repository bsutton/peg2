part of '../../operations.dart';

class ActionOperation extends Operation {
  List<Operation> arguments;

  List<String> code;

  ActionOperation(this.arguments, this.code);

  @override
  OperationKind get kind => OperationKind.action;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitAction(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      if (_relaceChild(argument, from, to, () => arguments[i] = to)) {
        return true;
      }
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    for (final argument in arguments) {
      argument.accept(visitor);
    }
  }
}

class BinaryOperation extends Operation {
  final OperationKind _kind;

  Operation left;

  Operation right;

  BinaryOperation(this.left, this._kind, this.right) {
    switch (kind) {
      case OperationKind.addAssign:
      case OperationKind.assign:
      case OperationKind.equal:
      case OperationKind.gt:
      case OperationKind.gte:
      case OperationKind.land:
      case OperationKind.lt:
      case OperationKind.lte:
      case OperationKind.lor:
        break;
      default:
        _errorInvalidOpertionKin();
    }
  }

  @override
  OperationKind get kind => _kind;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitBinary(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(left, from, to, () => left = to)) {
      return true;
    }

    if (_relaceChild(right, from, to, () => right = to)) {
      return true;
    }

    return false;
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
    visitor.visitBlock(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    for (var i = 0; i < operations.length; i++) {
      final operation = operations[i];
      if (_relaceChild(operation, from, to, () => operations[i] = to)) {
        return true;
      }
    }

    return false;
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
    visitor.visitBreak(this);
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
    visitor.visitCall(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      if (_relaceChild(argument, from, to, () => arguments[i] = to)) {
        return true;
      }
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    function.accept(visitor);
    for (final argument in arguments) {
      argument.accept(visitor);
    }
  }
}

class CommentOperation extends Operation {
  bool isDocComment;

  String text;

  CommentOperation(this.text, [this.isDocComment = false]);

  @override
  OperationKind get kind => OperationKind.comment;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitComment(this);
  }
}

class ConditionalOperation extends Operation {
  BlockOperation ifFalse;

  BlockOperation ifTrue;

  Operation test;

  ConditionalOperation(this.test, this.ifTrue, [this.ifFalse]) {
    if (test == null) {
      throw ArgumentError.notNull('test');
    }

    if (ifTrue == null) {
      throw ArgumentError.notNull('ifTrue');
    }
  }

  @override
  OperationKind get kind => OperationKind.conditional;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitConditional(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(test, from, to, () => test = to)) {
      return true;
    }

    return false;
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

  ConstantOperation(this.value) {
    if (value is num || value is bool || value is String || value == null) {
      //
    } else {
      throw ArgumentError('Unknown constant type: ${value.runtimeType}');
    }
  }

  @override
  OperationKind get kind => OperationKind.constant;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitConstant(this);
  }
}

class ListAccessOperation extends Operation {
  Operation list;

  Operation index;

  ListAccessOperation(this.list, this.index);

  @override
  OperationKind get kind => OperationKind.listAccess;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitListAccess(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(list, from, to, () => list = to)) {
      return true;
    }

    if (_relaceChild(index, from, to, () => index = to)) {
      return true;
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    list.accept(visitor);
    index.accept(visitor);
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
    visitor.visitList(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (_relaceChild(element, from, to, () => elements[i] = to)) {
        return true;
      }
    }

    return false;
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
    visitor.visitLoop(this);
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    body.accept(visitor);
  }
}

class MemberAccessOperation extends Operation {
  Operation member;

  Operation owner;

  MemberAccessOperation(this.owner, this.member);

  @override
  OperationKind get kind => OperationKind.memberAccess;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitMemberAccess(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(owner, from, to, () => owner = to)) {
      return true;
    }

    if (_relaceChild(member, from, to, () => member = to)) {
      return true;
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    owner.accept(visitor);
    member.accept(visitor);
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
    visitor.visitMethod(this);
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
  String text;

  NopOperation([this.text]);

  @override
  OperationKind get kind => OperationKind.nop;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitNop(this);
  }
}

abstract class Operation {
  Operation parent;

  OperationKind get kind;

  void accept(OperationVisitor visitor);

  MethodOperation getMethod() {
    var parent = this.parent;
    while (true) {
      if (parent is MethodOperation) {
        return parent;
      } else if (parent == null) {
        return null;
      }

      parent = parent.parent;
    }
  }

  bool replaceChild(Operation from, Operation to) {
    throw UnsupportedError('replaceChild');
  }

  void visitChildren(OperationVisitor visitor) {
    //
  }

  void _errorInvalidOpertionKin() {
    throw StateError('Invalid opertion kind: $kind');
  }

  bool _relaceChild(
      Operation op, Operation from, Operation to, void Function() replace) {
    if (op == from) {
      from.parent = null;
      to.parent = this;
      replace();
      return true;
    }

    return false;
  }
}

enum OperationKind {
  action,
  addAssign,
  assign,
  block,
  break_,
  call,
  comment,
  conditional,
  constant,
  convert,
  equal,
  gt,
  gte,
  land,
  list,
  listAccess,
  loop,
  lor,
  lt,
  lte,
  memberAccess,
  method,
  nop,
  not,
  parameter,
  postDec,
  postInc,
  preDec,
  preInc,
  return_,
  ternary,
  variable,
}

class ParameterOperation extends Operation {
  Operation operation;

  String type;

  Variable variable;

  ParameterOperation(this.type, this.variable, [this.operation]) {
    variable.declaration = this;
  }

  @override
  OperationKind get kind => OperationKind.parameter;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitParameter(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(operation, from, to, () => operation = to)) {
      return true;
    }

    return false;
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
    visitor.visitReturn(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(operation, from, to, () => operation = to)) {
      return true;
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    operation?.accept(visitor);
  }
}

class TernaryOperation extends Operation {
  Operation ifFalse;

  Operation ifTrue;

  Operation test;

  TernaryOperation(this.test, this.ifTrue, this.ifFalse);

  @override
  OperationKind get kind => OperationKind.ternary;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitTernary(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(test, from, to, () => test = to)) {
      return true;
    }

    if (_relaceChild(ifTrue, from, to, () => ifTrue = to)) {
      return true;
    }

    if (_relaceChild(ifFalse, from, to, () => ifFalse = to)) {
      return true;
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    test.accept(visitor);
    ifTrue.accept(visitor);
    ifFalse?.accept(visitor);
  }
}

class UnaryOperation extends Operation {
  @override
  final OperationKind kind;

  Operation operand;

  String type;

  UnaryOperation(this.kind, this.operand, [this.type]) {
    switch (kind) {
      case OperationKind.not:
      case OperationKind.preDec:
      case OperationKind.preInc:
      case OperationKind.postDec:
      case OperationKind.postInc:
        break;
      case OperationKind.convert:
        if (type == null) {
          throw ArgumentError.notNull('type');
        }

        break;
      default:
        _errorInvalidOpertionKin();
    }
  }

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitUnary(this);
  }

  @override
  bool replaceChild(Operation from, Operation to) {
    if (_relaceChild(operand, from, to, () => operand = to)) {
      return true;
    }

    return false;
  }

  @override
  void visitChildren(OperationVisitor visitor) {
    operand.accept(visitor);
  }
}

class Variable {
  bool frozen;

  ParameterOperation declaration;

  String name;

  Variable(this.name, [this.frozen = false]);

  @override
  String toString() {
    return name;
  }
}

class VariableOperation extends Operation {
  Variable variable;

  VariableOperation(this.variable) {
    if (variable == null) {
      throw ArgumentError.notNull('variable');
    }
  }

  @override
  OperationKind get kind => OperationKind.variable;

  @override
  void accept(OperationVisitor visitor) {
    visitor.visitVariable(this);
  }
}
