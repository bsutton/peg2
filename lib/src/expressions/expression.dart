part of '../../expressions.dart';

abstract class Expression {
  int id;

  int index;

  bool isLast = false;

  int level;

  Expression parent;

  String returnType = 'dynamic';

  ProductionRule rule;

  String variable;

  bool used;

  dynamic accept(ExpressionVisitor visitor);

  dynamic visitChildren(ExpressionVisitor visitor) {
    return null;
  }
}
