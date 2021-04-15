// @dart = 2.10
part of '../../general_parser_generator.dart';

class ExpressionsGenerator extends ExpressionsGeneratorBase {
  ExpressionsGenerator(
      {@required VariableAllocator allocator,
      @required List<Code> code,
      @required BitFlagGenerator failures,
      @required ClassMembers members,
      @required bool optimize})
      : super(
            allocator: allocator,
            code: code,
            failures: failures,
            members: members,
            optimize: optimize);

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final variable = allocNodeVar(node);
    final rule = node.rule;
    final level = node.level;
    final expressions = node.expressions;
    void failure(List<Code> code) {
      if (rule.kind == ProductionRuleKind.terminal &&
          level == 0 &&
          !node.isOptional) {
        final arguments = <_cb.Expression>[];
        arguments.add(literalString(rule.name));
        final condition = call$(Members.fail, arguments);
        code <<
            if$(condition, (code) {
              final terminalId = rule.terminalId;
              final setFlag = failures.generateSet(true, [terminalId]);
              code << Code(setFlag.join('\n'));
            });
      }
    }

    if (rule.kind == ProductionRuleKind.terminal &&
        level == 0 &&
        !node.isOptional) {
      code << assign(Members.failPos, refer(Members.pos));
    }

    if (variable != null) {
      final returnType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(returnType), variable);
    }

    if (expressions.length > 1) {
      switch (rule.kind) {
        case ProductionRuleKind.nonterminal:
          _generateOrderedChoiceNonterminal(node, variable, failure);
          break;
        default:
          _generateOrderedChoiceTerminal(node, variable, failure);
      }
    } else {
      _generateOrderedChoiceWithOneElement(node, variable, failure);
    }

    childVariable = variable;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final variable = allocNodeVar(node);
    final startCharacters = node.startCharacters;
    final localVariables = <String>[];
    final semanticVariables = <String>[];
    final types = <String>[];
    final code$ = code;
    if (variable != null) {
      final resultType = Utils.getNullableType(node.resultType);
      code << declareVariable(refer(resultType), variable);
    }

    void generate() {
      generateSequence(node, variable, 0,
          localVariables: localVariables,
          semanticVariables: semanticVariables,
          types: types);
    }

    final rule = node.rule;
    var canPredict = false;
    if (optimize) {
      if (rule.isTerminal || rule.isSubterminal && optimize) {
        final groups = startCharacters.groups;
        if (groups.length == 1) {
          canPredict = true;
        }
      }
    }

    if (canPredict) {
      final groups = startCharacters.groups;
      final group = groups.first;
      final start = group.start;
      final end = group.end;
      _cb.Expression condition;
      if (start == end) {
        condition = refer(Members.ch).equalTo(literal(start));
      } else {
        condition = refer(Members.ch)
            .greaterOrEqualTo(literal(start))
            .and(refer(Members.ch).lessOrEqualTo(literal(end)));
      }

      code << assign(Members.ok, literalFalse);
      code <<
          if$(condition, (code) {
            runBlock(code, generate);
          });
    } else {
      runBlock(code, generate);
    }

    code = code$;
    childVariable = variable;
  }

  void _generateOrderedChoiceNonterminal(OrderedChoiceExpression node,
      String variable, void Function(List<Code>) failure) {
    final expressions = node.expressions;
    var needSavePos = false;
    for (final child in expressions) {
      if (canSequenceChangePos(child)) {
        needSavePos = true;
        break;
      }
    }

    final storage = <String, String>{};
    addStoreVar(code, Members.ch, storage);
    if (needSavePos) {
      addStoreVar(code, Members.pos, storage);
    }

    code <<
        while$(literalTrue, (code) {
          for (var i = 0; i < expressions.length; i++) {
            final child = expressions[i];
            acceptNode(child, code);
            void success(List<Code> code) {
              if (variable != null) {
                code << assign(variable, refer(childVariable));
              }

              code << break$;
            }

            generateEpilogue(child, code, success, null);
            if (canSequenceChangePos(child)) {
              addRestoreVars(code, storage);
            } else {
              addRestoreVar(code, Members.ch, storage);
            }
          }

          code << break$;
        });

    failure(code);
    if (node.level == 0) {
      code << refer(variable).returned.statement;
    }
  }

  void _generateOrderedChoiceTerminal(OrderedChoiceExpression node,
      String variable, void Function(List<Code>) failure) {
    final expressions = node.expressions;
    var needSavePos = false;
    for (final child in expressions) {
      if (canSequenceChangePos(child)) {
        needSavePos = true;
        break;
      }
    }

    final storage = <String, String>{};
    addStoreVar(code, Members.ch, storage);
    if (needSavePos) {
      addStoreVar(code, Members.pos, storage);
    }

    code <<
        while$(literalTrue, (code) {
          for (var i = 0; i < expressions.length; i++) {
            final child = expressions[i];
            acceptNode(child, code);
            void success(List<Code> code) {
              if (variable != null) {
                code << assign(variable, refer(childVariable));
              }

              code << break$;
            }

            generateEpilogue(child, code, success, null);
            if (canSequenceChangePos(child)) {
              addRestoreVars(code, storage);
            } else {
              addRestoreVar(code, Members.ch, storage);
            }
          }

          code << break$;
        });

    failure(code);
    if (node.level == 0) {
      code << refer(variable).returned.statement;
    }
  }

  void _generateOrderedChoiceWithOneElement(OrderedChoiceExpression node,
      String variable, void Function(List<Code>) failure) {
    final child = node.expressions[0];
    final needSavePos = canSequenceChangePos(child);
    if (variable != null) {
      childVariable = allocator.alloc();
    }

    final storage = <String, String>{};
    if (needSavePos) {
      addStoreVar(code, Members.ch, storage);
      addStoreVar(code, Members.pos, storage);
    }

    acceptNode(child, code);
    void success(List<Code> code) {
      if (variable != null) {
        code << assign(variable, refer(childVariable));
      }
    }

    void fail(List<Code> code) {
      addRestoreVars(code, storage);
      failure(code);
      failBlocks[node] = code;
    }

    generateEpilogue(child, code, success, fail);
    if (node.level == 0) {
      if (variable == null) {
        code << literalNull.returned.statement;
      } else {
        code << refer(variable).returned.statement;
      }
    }
  }
}
