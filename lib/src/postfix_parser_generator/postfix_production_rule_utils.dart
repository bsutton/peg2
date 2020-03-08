part of '../../postfix_parser_generator.dart';

class PostfixProductionRuleUtils {
  String getExpressionMethodName(Expression expression) {
    final id = expression.id;
    final name = '_e$id';
    return name;
  }

  String getMethodName(ProductionRule rule) {
    final expression = rule.expression;
    return getExpressionMethodName(expression);
  }
}
