import 'package:code_builder/code_builder.dart';

import '../helpers/expression_helper.dart';

class CodeBlock {
  final List<Code> _code = [];

  Code get code => lazyCode(() => Block.of(_code));

  bool get isEmpty => _code.isEmpty;

  void addBlock(List<Code> code) {
    addCode(Block.of(code));
  }

  void addCode(Code code) {
    _code.add(code);
  }

  void addLazyCode(Code Function() generate) {
    _code.add(lazyCode(generate));
  }

  void addSourceCode(String source) {
    _code.add(Code(source));
  }

  void addStatement(Expression expression) {
    addCode(expression.statement);
  }

  void assign(String name, Expression expression) {
    addStatement(refer(name).assign(expression));
  }

  void assignConst(String name, Expression expression, [Reference? type]) {
    addStatement(expression.assignConst(name, type));
  }

  void assignFinal(String name, Expression expression, [Reference? type]) {
    addStatement(expression.assignFinal(name, type));
  }

  void assignVar(String name, Expression expression, [Reference? type]) {
    addStatement(expression.assignVar(name, type));
  }

  void break$() {
    addCode(const Code('break;'));
  }

  void callAndTryAssignFinal(String? name, Expression call) {
    if (name != null) {
      assignFinal(name, call);
    } else {
      addStatement(call);
    }
  }

  void declare(String name, Reference type, [Expression? assignment]) {
    _declare(name, type, assignment: assignment);
  }

  void doWhile$(Expression control, void Function(CodeBlock block) body) {
    final blockEnd = CodeBlock();
    blockEnd.addCode(Code('while ('));
    blockEnd.addCode(control.code);
    blockEnd.addCode(Code(');'));
    _controlFlowStatement('do', null, body, blockEnd.code);
  }

  void else$(void Function(CodeBlock block) body) {
    _controlFlowStatement('if else', null, body);
  }

  void for$(Code control, void Function(CodeBlock block) body) {
    _controlFlowStatement('if else', control, body);
  }

  void if$(Expression control, void Function(CodeBlock block) body) {
    _controlFlowStatement('if', control.code, body);
  }

  void ifElse$(Expression control, void Function(CodeBlock block) body) {
    _controlFlowStatement('if else', control.code, body);
  }

  void tryAssign(String? name, Expression Function() assignment) {
    if (name != null) {
      assign(name, assignment());
    }
  }

  void tryAssignFinal(String? name, Expression Function() assignment) {
    if (name != null) {
      assign(name, assignment());
    }
  }

  void tryDeclare(String? name, Reference type,
      [Expression Function()? assignment]) {
    if (name != null) {
      Expression? value;
      if (assignment != null) {
        value = assignment();
      }

      declare(name, type, value);
    }
  }

  void while$(Expression expression, void Function(CodeBlock block) body) {
    _controlFlowStatement('while', expression.code, body);
  }

  void _controlFlowStatement(
      String name, Code? control, void Function(CodeBlock block) body,
      [Code? blockEnd]) {
    final block = CodeBlock();
    addCode(Code(name));
    if (control != null) {
      addCode(Code(' ('));
      addCode(control);
      addCode(Code(')'));
    }

    addCode(Code(' {'));
    addCode(block.code);
    addCode(Code('}'));
    if (blockEnd != null) {
      addCode(blockEnd);
    }

    body(block);
  }

  void _declare(String name, Reference? type,
      {Expression? assignment, String? modifier}) {
    if (type == null && modifier == null) {
      throw StateError('Both type and modifier cannot be null');
    }
    final code = <Code>[];
    if (modifier != null) {
      code.add(Code(modifier));
      code.add(const Code(' '));
    }

    if (type != null) {
      code.add(type.code);
      code.add(const Code(' '));
    }

    code.add(ref(name).code);
    if (assignment != null) {
      code.add(const Code(' = '));
      code.add(assignment.code);
    }

    code.add(const Code(';'));
    addBlock(code);
  }
}
