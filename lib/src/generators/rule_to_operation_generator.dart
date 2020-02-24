part of '../../generators.dart';

class RulesToOperationsGenerator extends ExpressionToOperationGenerator
    with OperationUtils {
  Map<Expression, ProductionRule> _topExpressions;

  final Grammar grammar;

  RulesToOperationsGenerator(this.grammar, ParserGeneratorOptions options)
      : super(options);

  List<MethodOperation> build() {
    if (grammar == null) {
      throw ArgumentError.notNull('grammar');
    }

    _topExpressions = {};
    final rules = grammar.rules;
    for (var rule in rules) {
      _topExpressions[rule.expression] = rule;
    }

    final result = <MethodOperation>[];
    for (final rule in rules) {
      var skip = false;
      if (rule.callers.length == 1) {
        switch (rule.kind) {
          case ProductionRuleKind.Nonterminal:
            if (options.inlineNonterminals) {
              skip = true;
            }

            break;
          case ProductionRuleKind.Subterminal:
            if (options.inlineSubterminals) {
              skip = true;
            }

            break;
          default:
        }
      }

      if (!skip) {
        final method = _buildRule(rule);
        result.add(method);
      }
    }

    return result;
  }

  @override
  String getRuleMethodName(ProductionRule rule) {
    var name = rule.name;
    switch (rule.kind) {
      case ProductionRuleKind.Nonterminal:
        break;
      case ProductionRuleKind.Terminal:
        name = _getTerminalName(name, rule.id);
        break;
      case ProductionRuleKind.Subterminal:
        name = '\$\$' + name.substring(1);
    }

    final result = '_parse$name';
    return result;
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final b = block;
    final expressions = node.expressions;
    final returnType = node.returnType;
    final result = varAlloc.newVar(b, returnType, null);
    if (expressions.length > 1) {
      addLoop(b, (b) {
        block = b;
        for (var i = 0; i < expressions.length; i++) {
          final child = expressions[i];
          child.accept(this);
          if (i < expressions.length - 1) {
            addIfVar(b, m.success, (b) {
              addAssign(b, varOp(result), varOp(resultVar));
              addBreak(b);
            });
          } else {
            addIfVar(b, m.success, (b) {
              addAssign(b, varOp(result), varOp(resultVar));
            });

            addBreak(b);
          }
        }
      });
    } else {
      final child = expressions[0];
      child.accept(this);
      addAssign(b, varOp(result), varOp(resultVar));
    }

    resultVar = result;
    block = b;
  }

  MethodOperation _buildRule(ProductionRule rule) {
    varAlloc = getLocalVarAlloc();
    final cid = varAlloc.alloc();
    final id = rule.expression.id;
    productive = varAlloc.alloc();
    final name = getRuleMethodName(rule);
    final params = <ParameterOperation>[];
    params.add(ParameterOperation('int', cid));
    params.add(ParameterOperation('bool', productive));
    var returnType = rule.returnType;
    returnType ??= rule.expression.returnType;
    Variable start;
    final result = addMethod(returnType, name, params, (b) {
      block = b;
      if (options.memoize && rule.callers.length > 1) {
        final memoized = callOp(varOp(m.memoized), [constOp(id), varOp(cid)]);
        addIf(b, memoized, (b) {
          final convert = convertOp(varOp(m.mresult), returnType);
          addReturn(b, convert);
        });

        start = varAlloc.newVar(b, 'var', varOp(m.pos));
      }

      if (rule.kind == ProductionRuleKind.Terminal) {
        addAssign(b, varOp(m.fposEnd), constOp(-1));
        start ??= varAlloc.newVar(b, 'var', varOp(m.pos));
      }

      final result = varAlloc.newVar(b, returnType, null);
      final expression = rule.expression;
      expression.accept(this);
      addAssign(b, varOp(result), varOp(resultVar));
      if (rule.kind == ProductionRuleKind.Terminal) {
        addIfNotVar(b, m.success, (b) {
          final params = [varOp(start), constOp(rule.name)];
          final fail = callOp(varOp(m.fail), params);
          addOp(b, fail);
        });
      }

      if (options.memoize && rule.callers.length > 1) {
        final listAccess = ListAccessOperation(varOp(m.memoizable), varOp(cid));
        final test =
            BinaryOperation(listAccess, OperationKind.equal, constOp(true));
        addIf(b, test, (b) {
          final memoize = callOp(
              varOp(m.memoize), [constOp(id), varOp(start), varOp(result)]);
          addOp(b, memoize);
        });
      }

      addReturn(b, varOp(result));
    });

    productive = null;
    return result;
  }

  String _getTerminalName(String name, int id) {
    name = name.substring(1, name.length - 1);
    const ascii00_31 = [
      'NUL',
      'SOH',
      'STX',
      'EOT',
      'EOT',
      'ENQ',
      'ACK',
      'BEL',
      'BS',
      'HT',
      'LF',
      'VT',
      'FF',
      'CR',
      'SO',
      'SI',
      'DLE',
      'DC1',
      'DC2',
      'DC3',
      'DC4',
      'NAK',
      'SYN',
      'ETB',
      'CAN',
      'EM',
      'SUB',
      'ESC',
      'FS',
      'GS',
      'RS',
      'US',
    ];

    const ascii32_47 = [
      'ExclamationMark',
      'DoubleQuotationMark',
      'NumberSign',
      'DollarSign',
      'PercentSign',
      'Ampersand',
      'Apostrophe',
      'LeftParenthesis',
      'RightParenthesis',
      'Asterisk',
      'PlusSign',
      'Comma',
      'MinusSign',
      'Period',
      'Slash',
    ];

    const ascii58_64 = [
      'Colon',
      'Semicolon',
      'LessThanSign',
      'EqualSign',
      'GreaterThanSign',
      'QuestionMark',
      'CommercialAtSign',
    ];

    const ascii91_96 = [
      'LeftSquareBracket',
      'Backslash',
      'RightSquareBracket',
      'SpacingCircumflexAccent',
      'SpacingUnderscore',
      'SpacingGraveAccent',
    ];

    const ascii123_127 = [
      'LeftBrace',
      'VerticalBar',
      'RightBrace',
      'TildeAccent',
      'Delete',
    ];

    final sb = StringBuffer();
    sb.write('_');
    var success = true;
    for (var i = 0; i < name.length; i++) {
      final c = name.codeUnitAt(i);
      if (c > 127) {
        success = false;
        break;
      }

      if (c >= 48 && c <= 57 || c >= 65 && c <= 90 || c >= 97 && c <= 122) {
        sb.write(name[i]);
      } else if (c == 32) {
        sb.write('_');
      } else if (c >= 0 && c <= 31) {
        sb.write('\$');
        sb.write(ascii00_31[c]);
      } else if (c >= 33 && c <= 47) {
        sb.write('\$');
        sb.write(ascii32_47[c - 33]);
      } else if (c >= 58 && c <= 64) {
        sb.write('\$');
        sb.write(ascii58_64[c - 58]);
      } else if (c >= 91 && c <= 96) {
        sb.write('\$');
        sb.write(ascii91_96[c - 91]);
      } else if (c >= 123 && c <= 127) {
        sb.write('\$');
        sb.write(ascii123_127[c - 123]);
      }
    }

    final result = sb.toString();
    if (!success || result.length > 32) {
      return '\$Terminal$id';
    }

    return result;
  }
}
