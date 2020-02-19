part of '../../expressions.dart';

abstract class Expression {
  int id;

  int index;

  bool isLast = false;

  bool isOptional = false;

  int level;

  Expression parent;

  String returnType = 'dynamic';

  ProductionRule rule;

  SparseBoolList startCharacters = SparseBoolList();

  String variable;

  bool used;

  dynamic accept(ExpressionVisitor visitor);

  dynamic visitChildren(ExpressionVisitor visitor) {
    return null;
  }
}
