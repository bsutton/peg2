import 'package:code_builder/code_builder.dart';
import 'package:peg2/src/generators/code_block.dart';

class IfElseGenerator {
  final Expression expression;

  final CodeBlock _elseCode = CodeBlock();

  final CodeBlock _ifCode = CodeBlock();

  IfElseGenerator(this.expression);

  void elseCode(void Function(CodeBlock block) body) {
    body(_elseCode);
  }

  CodeBlock generate() {
    final block = CodeBlock();
    if (!_ifCode.isEmpty) {
      block.if$(expression, (block) {
        block.addCode(_ifCode.code);
      });

      if (!_elseCode.isEmpty) {
        block.else$((block) {
          block.addCode(_elseCode.code);
        });
      }
    } else if (!_elseCode.isEmpty) {
      block.if$(expression.negate(), (block) {
        block.addCode(_elseCode.code);
      });
    }

    return block;
  }

  void ifCode(void Function(CodeBlock block) body) {
    body(_ifCode);
  }
}
