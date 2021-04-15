// @dart = 2.10
part of '../../general_parser_generator.dart';

class ParserGenerator extends ParserGeneratorBase {
  ParserGenerator(Grammar grammar, ParserGeneratorOptions options)
      : super(grammar, options);

  @override
  void addClassParser(List<Spec> specs) {
    final name = options.name + 'Parser';
    final generator = ParserClassGenerator(name, grammar, options);
    final spec = generator.generate();
    specs.add(spec);
  }
}
