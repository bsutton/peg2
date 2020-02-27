part of '../../expressions.dart';

abstract class Expression {
  int id;

  int index;

  bool isSilentMode = false;

  bool isLast = false;

  bool isOptional = false;

  bool isProductive = false;

  bool isSuccessful = false;

  int level;

  Expression parent;

  String returnType = 'dynamic';

  ProductionRule rule;

  SparseBoolList startCharacters = SparseBoolList();

  String variable;

  bool used;

  void accept(ExpressionVisitor visitor);

  void visitChildren(ExpressionVisitor visitor) {
    //
  }
}
