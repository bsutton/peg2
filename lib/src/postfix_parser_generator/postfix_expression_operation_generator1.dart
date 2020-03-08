part of '../../postfix_parser_generator.dart';

class PostfixExpressionOperationGenerator1
    extends PostfixExpressionOperationGenerator0 {
  PostfixExpressionOperationGenerator1(ParserGeneratorOptions options,
      BlockOperation block, VariableAllocator va, this.c, this.pos)
      : super(options, block, va);

  final Variable c;

  final Variable pos;

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    result = va.newVar(block, 'final', null);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    result = va.newVar(block, 'final', varOp(c));
  }

  @override
  void visitCapture(CaptureExpression node) {
    final substring = Variable('substring', true);
    final call = mbrCallOp(
        varOp(m.text), varOp(substring), [varOp(startPos), varOp(m.pos)]);
    result = va.newVar(block, 'final', call);
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    result = va.newVar(block, 'final', varOp(c));
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final text = node.text;
    final runes = text.runes.toList();
    if (runes.isEmpty) {
      result = va.newVar(block, 'final', constOp(''));
    } else if (runes.length == 1) {
      result = va.newVar(block, 'final', constOp(text));
    } else {
      final offset = runes.first > 0xffff ? 1 : 0;
      final text1 = text.substring(1 + offset);
      final matchString2 =
          callOp(varOp(m.matchString2), [constOp(text1), constOp(text)]);
      result = va.newVar(block, 'final', matchString2);
    }
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final notSuccess = notOp(varOp(m.success));
    addAssign(block, varOp(m.success), notSuccess);
    result = va.newVar(block, 'final', null);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    Variable result1;
    if (isProductive) {
      addIfVar(block, productive, (block) {
        final list = listOp(null, [varOp(result)]);
        result1 = va.newVar(block, 'final', list);
      });
    } else {
      final returnType = node.returnType;
      result1 = va.newVar(block, returnType, null);
    }

    addLoop(block, (block) {
      final child = node.expression;
      final generator =
          PostfixExpressionOperationGenerator0(options, block, va);
      visitChild(generator, child, block);
      addIfNotVar(block, m.success, addBreak);
      final add = Variable('add');
      addMbrCall(block, varOp(result), varOp(add), [varOp(result)]);
    });

    result = result1;
  }

  @override
  void visitOptional(OptionalExpression node) {
    //
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    //
  }
}
