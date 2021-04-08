// @dart = 2.10
part of '../../parser_generator.dart';

class ParserGeneratorOptions {
  bool memoize;

  String name;

  ParserGeneratorOptions({this.memoize = false, @required this.name});
}
