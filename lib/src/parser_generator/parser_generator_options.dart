part of '../../parser_generator.dart';

class ParserGeneratorOptions {
  bool inlineNonterminals = false;

  bool inlineSubterminals = false;

  bool inlineTerminals = false;

  bool memoize = false;

  String name;

  bool optimizeCode = true;

  String parserType = 'general';

  bool predict = false;

  bool isPostfix() {
    switch (parserType) {
      case 'general':
        return false;
      case 'postfix':
        return true;
    }

    throw StateError('Unknown parser type: $parserType');
  }
}
