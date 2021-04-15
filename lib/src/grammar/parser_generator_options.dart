part of '../../grammar.dart';

class ParserGeneratorOptions {
  bool memoize;

  String name;

  bool optimize;

  ParserGeneratorOptions(
      {this.memoize = false, this.optimize = false, required this.name});
}
