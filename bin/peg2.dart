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
  argParser.addFlag('inline-all',
      defaultsTo: false, help: 'Convert all calls into inline expressions');
  argParser.addFlag('inline-nonterminals',
      defaultsTo: false,
      help: 'Convert nonterminal calls into inline expressions');
  argParser.addFlag('inline-subterminals',
      defaultsTo: false,
      help: 'Convert subterminal calls into inline expressions');
  argParser.addFlag('inline-terminals',
      defaultsTo: false,
      help: 'Convert terminal calls into inline expressions');
  argParser.addFlag('memoize',
      defaultsTo: false, help: 'Memoize results of calls');
  argParser.addOption('parser',
      allowed: ['general', 'postfix'],
      defaultsTo: 'general',
      help: 'Type of generated perser');
  argParser.addFlag('print',
      abbr: 'p', defaultsTo: false, help: 'Print grammar');
  argParser.addFlag('predict',
      defaultsTo: false,
      help:
          'Reduces the number of calls predicted by the start characters of the rules');
  final argResults = argParser.parse(args);
  final printGrammar = argResults['print'] as bool;
  options.inlineNonterminals = argResults['inline-nonterminals'] as bool;
  options.inlineSubterminals = argResults['inline-subterminals'] as bool;
  options.inlineTerminals = argResults['inline-terminals'] as bool;
  options.memoize = argResults['memoize'] as bool;
  options.parserType = argResults['parser'] as String;
  options.predict = argResults['predict'] as bool;
  if (argResults['inline-all'] as bool) {
    options.inlineNonterminals = true;
    options.inlineSubterminals = true;
    options.inlineTerminals = true;
  }

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
  final parserGenerator = ParserGenerator(grammar, options);
  final parserCode = parserGenerator.generate();
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
