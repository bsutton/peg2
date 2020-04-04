part of '../../finite_automaton.dart';

class ExpressionToEnfaConverter extends ExpressionToEnfaConverterBase {
  @override
  void separate(SymbolExpression node, EnfaState prev, EnfaState next) {
    prev.states.add(next);
  }
}
