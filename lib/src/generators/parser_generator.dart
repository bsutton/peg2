part of '../../generators.dart';

class ParserGenerator {
  String generate(Grammar grammar, ParserGeneratorOptions options) {
    final grammarAnalyzer = GrammarAnalyzer();
    final grammarErrors = grammarAnalyzer.analyze(grammar);
    if (grammarErrors.isNotEmpty) {
      for (var error in grammarErrors) {
        print(error);
      }

      return null;
    }

    final rulesToOperationsBuilder = RulesToOperationsBuilder();
    final methods = rulesToOperationsBuilder.build(grammar, options);
    for (final method in methods) {
      final operationsInitializer = OperationInitializer();
      operationsInitializer.initialize(method);
    }

    for (final method in methods) {
      final operationsOptimizer = OperationOptimizer();
      operationsOptimizer.optimize(method.body);
    }

    final operationsToCodeConverter = OperationsToCodeConverter();
    final methodBuilders = operationsToCodeConverter.convert(methods);
    final libraryBuilder = ContentBuilder();
    final lineSplitter = LineSplitter();
    if (grammar.globals != null) {
      final lines = lineSplitter.convert(grammar.globals);
      if (lines.isNotEmpty && lines[0].isEmpty) {
        lines.removeAt(0);
      }

      libraryBuilder.addAll(lines);
    }

    final parserClassBuilder = ParserClassBuilder();
    final name = options.name + 'Parser';
    parserClassBuilder.build(grammar, name, libraryBuilder, methodBuilders);
    libraryBuilder.add('// ignore_for_file: prefer_final_locals');
    libraryBuilder.add('// ignore_for_file: unused_element');
    libraryBuilder.add('// ignore_for_file: unused_field');
    libraryBuilder.add('// ignore_for_file: unused_local_variable');
    final formatter = DartFormatter();
    var source = libraryBuilder.build(0).join('\n');
    try {
      source = formatter.format(source);
      // ignore: unused_catch_clause
    } on FormatterException catch (e) {
      //
    }

    return source;
  }
}
