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

  //bool canMatchEof = false;

  int id;

  int index;

  bool isLast = false;

  bool isOptional = false;

  bool isSuccessful = false;

  int level;

  Expression parent;

  Productiveness productiveness = Productiveness.always;

  String returnType = 'dynamic';

  ProductionRule rule;

  final SparseBoolList startCharacters = SparseBoolList();

  final Set<ProductionRule> startTerminals = {};

  String variable;

  bool used;

  void accept(ExpressionVisitor visitor);

  void visitChildren(ExpressionVisitor visitor) {
    //
  }
}

enum Productiveness { always, auto, never }
