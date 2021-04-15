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

  bool resultUsed = false;

  String resultType = 'dynamic';

  ProductionRule? rule;

  final SparseBoolList startCharacters = SparseBoolList();

  final Set<ProductionRule> startTerminals = {};

  String? variable;

  ExpressionKind get kind;

  T accept<T>(ExpressionVisitor<T> visitor);

  void visitChildren<T>(ExpressionVisitor<T> visitor) {
    //
  }
}

enum ExpressionKind {
  andPredicate,
  anyCharacter,
  capture,
  characterClass,
  literal,
  nonterminal,
  notPredicate,
  oneOrMore,
  optional,
  orderedChoice,
  sequence,
  subterminal,
  terminal,
  zeroOrMore
}
