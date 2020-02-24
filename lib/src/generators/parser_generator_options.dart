part of '../../generators.dart';

class ParserGeneratorOptions {
  bool inlineNonterminals = false;

  bool inlineSubterminals = false;

  bool inlineTerminals = false;

  bool memoize = false;

  String name;

  bool optimizeOperations = true;

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
