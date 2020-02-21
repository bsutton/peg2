part of '../../generators.dart';

/*
class ExpressionCodeGenerator {
  static final c = Variable('_c');

  static final cp = Variable('_cp');

  static final pos = Variable('_pos');

  void genOptional(OptionalExpression expression, BlockOperation block) {
    //
  }

  void genNotPredicate(NotPredicateExpression node, BlockOperation block) {
    final child = node.expression;
    final state = saveVars(b, _allocVar, [
      c,
      cp,
      pos,
      _predicate,
      _productive,
    ]);

    addAssign(b, varOp(_predicate), constOp(true));
    addAssign(b, varOp(_productive), constOp(false));
    child.accept(this);
    _result = newVar(b, 'var', _allocVar, null);
    addAssign(b, varOp(_success), unaryOp(OperationKind.not, varOp(_success)));
    restoreVars(b, state);
  }
}
*/
