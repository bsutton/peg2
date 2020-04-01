part of '../../common_generators.dart';

class ProductionRuleUtils {
  bool needToInline(ProductionRule rule, ParserGeneratorOptions options) {
    final test = false;
    if (test) {
      // Max inline of subterminals?
      if (rule.kind == ProductionRuleKind.subterminal) {
        final callers = rule.allCallers.map((e) => e.rule.expression).toList();
        final inline = !callers.contains(rule.expression);
        return inline;
      }
    }

    var result = rule.directCallers.length == 1;
    if (result) {
      switch (rule.kind) {
        case ProductionRuleKind.nonterminal:
          result = options.inlineNonterminals;
          break;
        case ProductionRuleKind.terminal:
          result = options.inlineTerminals;
          break;
        case ProductionRuleKind.subterminal:
          result = options.inlineSubterminals;
          break;
        default:
      }
    }

    return result;
  }

  bool needToMemoize(ProductionRule rule, ParserGeneratorOptions options) {
    if (!options.memoize) {
      return false;
    }

    return rule.memoizationRequests.length > 1;
  }

  VariableAllocator newVarAlloc() {
    var id = 0;
    String allocate() {
      final name = '\$${id++}';
      return name;
    }

    final va = VariableAllocator(allocate);
    return va;
  }
}
