import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as _path;
import 'package:peg2/generators.dart';
import 'package:peg2/grammar.dart';
import 'package:strings/strings.dart';

import 'peg2_parser.dart';

void main(List<String> args) {
  final options = ParserGeneratorOptions();
  final argParser = ArgParser();
  argParser.addFlag('print',
      abbr: 'p', defaultsTo: false, help: 'Print grammar');
  final argResults = argParser.parse(args);
  final printGrammar = argResults['print'] as bool;
  String inputFilename;
  String outputFilename;
  if (argResults.rest.length == 1) {
    inputFilename = argResults.rest[0];
    outputFilename = _path.join(_path.dirname(inputFilename),
        _path.basenameWithoutExtension(inputFilename) + '_parser.dart');
  } else if (argResults.rest.length == 2) {
    inputFilename = argResults.rest[0];
    outputFilename = argResults.rest[1];
  } else {
    print('Usage: peg2 options infile [outfile]');
    print('Options:');
    print(argParser.usage);
    exit(-1);
  }

  final inputFile = File(inputFilename);
  if (!inputFile.existsSync()) {
    print('File not found: ${inputFilename}');
    exit(-1);
  }

  final grammarText = inputFile.readAsStringSync();
  final parser = Peg2Parser();
  final result = parser.parse(grammarText) as Grammar;
  if (parser.error != null) {
    throw parser.error;
  }

  final grammar = result;
  if (printGrammar) {
    _printGrammar(grammar);
  }

  final name = _path.basenameWithoutExtension(inputFilename);
  if (name.isEmpty) {
    print('Unable determine parser name');
    exit(-1);
  }

  options.name = camelize(name);
  final parserGenerator = ParserGenerator();
  final parserCode = parserGenerator.generate(grammar, options);
  if (parserCode == null) {
    print('Parser generation error');
    exit(-1);
  }

  final outputFile = File(outputFilename);
  outputFile.writeAsStringSync(parserCode);
}

void _printGrammar(Grammar grammar) {
  final sb = StringBuffer();
  final rules = grammar.rules;
  for (var rule in rules) {
    sb.write(rule.name);
    sb.writeln(' =');
    final choice = rule.expression;
    final sequences = choice.expressions;
    final length = sequences.length;
    for (var i = 0; i < length; i++) {
      final sequence = sequences[i];
      if (i > 0) {
        sb.write('  / ');
      } else {
        sb.write('  ');
      }

      sb.writeln(sequence);
    }

    sb.writeln('  ;');
    sb.writeln('');
  }

  print(sb);
}
