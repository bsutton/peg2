// @dart = 2.10
part of '../../generators.dart';

class IdentifierHelper {
  static String getActionIdentifier(int id) {
    return '_\$a$id';
  }

  static String getExpressionIdentifier(Expression expression) {
    final id = expression.id;
    return '_\$e$id';
  }

  static String getRuleIdentifier(ProductionRule rule) {
    final generator = ProductionRuleNameGenerator();
    return generator.generate(rule);
  }
}
