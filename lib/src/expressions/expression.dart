part of '../../expressions.dart';

abstract class Expression {
  static const int eof = maxUnicode + 1;

  static const int maxUnicode = 0x10ffff;

  static final SparseBoolList allChararcters = SparseBoolList()
    ..addGroup(GroupedRangeList<bool>(0, maxUnicode, true))
    ..freeze();

  static final SparseBoolList allChararctersWithEof = SparseBoolList()
    ..addGroup(GroupedRangeList<bool>(0, eof, true))
    ..freeze();

  int? id;

  int? index;

  bool isLast = false;

  bool isOptional = false;

  bool isSuccessful = false;

  int? level;

  Expression? parent;

  String returnType = 'dynamic';

  ProductionRule? rule;

  final SparseBoolList startCharacters = SparseBoolList();

  final Set<ProductionRule> startTerminals = {};

  String? variable;

  bool used = false;

  T accept<T>(ExpressionVisitor<T> visitor);

  String nullCheckedValue(String value) {
    if (returnType == 'dynamic') {
      return value;
    }

    if (returnType == 'dynamic!') {
      return value;
    }

    if (isOptional) {
      return value;
    }

    if (this is OneOrMoreExpression) {
      return value;
    }

    if (this is ZeroOrMoreExpression) {
      return value;
    }

    return '$value!';
  }

  void visitChildren<T>(ExpressionVisitor<T> visitor) {
    //
  }
}
