part of '../../operation_generators.dart';

abstract class ExpressionToOperationGenerator extends ExpressionVisitor {
  BlockOperation _block;

  final ParserClassMembers _members = ParserClassMembers();

  int lastVariableIndex;

  Variable _allocVar() {
    final result = Variable('\$${lastVariableIndex++}');
    return result;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final b = _block;
    final child = node.expression;
    final state = saveVars(b, _allocVar, [
      _members.c,
      _members.cp,
      _members.pos,
      _members.predicate,
      _members.productive,
    ]);

    addAssign(b, varOp(_members.predicate), constOp(true));
    addAssign(b, varOp(_members.productive), constOp(false));
    child.accept(this);
    final result = newVar(b, 'var', _allocVar, null);
    restoreVars(b, state);
    //_result = result;
  }
}
