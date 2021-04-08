// @dart = 2.10
part of '../../parser_generator.dart';

class Utils {
  static String escapeString(String text, [bool quote = true]) {
    final result = text.replaceAll('\'', '\\\'').replaceAll('\n', '\\n');
    if (!quote) {
      return result;
    }

    return '\'$result\'';
  }

  static String getExpressionIdentifier(Expression expression) {
    final id = expression.id;
    return '_\$e$id';
  }

  static String getActionIdentifier(int id) {
    return '_\$a$id';
  }

  static String getRuleIdentifier(ProductionRule rule) {
    final generator = ProductionRuleNameGenerator();
    return generator.generate(rule);
  }
}
