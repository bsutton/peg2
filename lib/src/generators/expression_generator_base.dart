// @dart = 2.10
part of '../../generators.dart';

abstract class ExpressionsGeneratorBase extends ExpressionVisitor<void> {
  VariableAllocator allocator;

  String childVariable;

  List<Code> code;

  final BitFlagGenerator failures;

  final ClassMembers members;

  final Map<Expression, List<Code>> failBlocks = {};

  final bool optimize;

  final Map<Expression, List<Code>> successBlocks = {};

  ExpressionsGeneratorBase(
      {@required this.allocator,
      @required this.code,
      @required this.failures,
      @required this.members,
      @required this.optimize});

  void acceptNode(Expression node, List<Code> code) {
    runBlock(code, () => node.accept(this));
  }

  void acceptSequenceElement(Expression node, List<Code> code,
      {@required List<String> localVariables,
      @required List<String> semanticVariables,
      @required List<String> types}) {
    acceptNode(node, code);
    semanticVariables.add(node.variable);
    types.add(node.resultType);
    localVariables.add(childVariable);
  }

  String addAllocFinal(List<Code> code, _cb.Expression expression) {
    final variable = allocator.alloc();
    return addAssignFinal(code, variable, expression);
  }

  void addAssign(
      List<Code> code, String name, _cb.Expression Function() expression) {
    if (name != null) {
      code << assign(name, expression());
    }
  }

  String addAssignFinal(
      List<Code> code, String name, _cb.Expression expression) {
    if (name != null) {
      code << assignFinal(name, expression);
    }

    return name;
  }

  String addAssignFinalOrExpression(
      List<Code> code, String name, _cb.Expression expression) {
    if (name != null) {
      code << assignFinal(name, expression);
    } else {
      code << expression.statement;
    }

    return name;
  }

  void addDeclareVar(List<Code> code, String name, Reference type) {
    if (name != null) {
      code << declareVariable(type, name);
    }
  }

  String addNodeVar(List<Code> code, Expression node) {
    String variable;
    if (node.resultUsed) {
      variable = allocator.alloc();
      final resultType = Utils.getNullableType(node.resultType);
      addDeclareVar(code, variable, refer(resultType));
    }

    return variable;
  }

  String addNodeVarOrExpression(List<Code> code, _cb.Expression expression) {
    final variable = allocator.alloc();
    return addAssignFinalOrExpression(code, variable, expression);
  }

  void addRestoreVar(
      List<Code> code, String name, Map<String, String> storage) {
    if (!storage.containsKey(name)) {
      throw StateError('The variable was not stored: $name');
    }

    final variable = storage[name];
    code << assign(name, refer(variable));
  }

  void addRestoreVars(List<Code> code, Map<String, String> storage) {
    for (final key in storage.keys) {
      addRestoreVar(code, key, storage);
    }
  }

  String addStoreVar(
      List<Code> code, String name, Map<String, String> storage) {
    if (storage.containsKey(name)) {
      throw StateError('Variable already stored: $name');
    }

    final variable = allocator.alloc();
    code << assignFinal(variable, refer(name));
    storage[name] = variable;
    return variable;
  }

  String allocNodeVar(Expression node) {
    if (node.resultUsed) {
      return allocator.alloc();
    }

    return null;
  }

  void generateEpilogue(Expression node, List<Code> code,
      Function(List<Code>) success, Function(List<Code>) fail) {
    final successBlock = successBlocks[node];
    final failBlock = failBlocks[node];
    if (successBlock != null && success != null) {
      success(successBlock);
      success = null;
    }

    if (failBlock != null && fail != null) {
      fail(failBlock);
      fail = null;
    }

    if (success != null || fail != null) {
      final ifElse = IfElseGenerator(refer(Members.ok));
      if (success != null) {
        ifElse.ifCode(success);
      }

      if (fail != null) {
        ifElse.elseCode(fail);
      }

      code << lazyCode(() => Block.of(ifElse.generate()));
    }
  }

  void generateSequence(SequenceExpression node, String variable, int index,
      {@required List<String> localVariables,
      @required List<String> semanticVariables,
      @required List<String> types}) {
    final expressions = node.expressions;
    for (var i = index; i < expressions.length; i++) {
      final child = expressions[i];
      if (i > 0 && !expressions[i - 1].isOptional) {
        code <<
            if$(refer(Members.ok), (code) {
              this.code = code;
              acceptSequenceElement(child, code,
                  localVariables: localVariables,
                  semanticVariables: semanticVariables,
                  types: types);
            });
      } else {
        acceptSequenceElement(child, code,
            localVariables: localVariables,
            semanticVariables: semanticVariables,
            types: types);
      }
    }

    generateSequenceAction(node, code, variable,
        localVariables: localVariables,
        semanticVariables: semanticVariables,
        types: types);
  }

  void generateSequenceAction(
      SequenceExpression node, List<Code> code, String variable,
      {@required List<String> localVariables,
      @required List<String> semanticVariables,
      @required List<String> types}) {
    final expressions = node.expressions;
    if (variable != null || node.actionIndex != null) {
      final errors = <String>[];
      void action(List<Code> code) {
        final generator = ActionCodeGenerator(
          code: code,
          actionSource: node.actionSource,
          localVariables: localVariables,
          resultType: node.resultType,
          semanticVariables: semanticVariables,
          types: types,
          variable: variable,
        );
        generator.generate(errors);
        if (errors.isNotEmpty) {
          final message = 'Error generating result for expression: $node';
          throw StateError(message);
        }
      }

      if (expressions.last.isOptional) {
        action(code);
        successBlocks[node] = code;
      } else {
        code <<
            if$(refer(Members.ok), (code) {
              action(code);
              successBlocks[node] = code;
            });
      }
    }
  }

  bool needSaveChForExpression(Expression node, Set<Expression> processed) {
    if (!processed.add(node)) {
      return true;
    }

    switch (node.kind) {
      case ExpressionKind.andPredicate:
      case ExpressionKind.anyCharacter:
      case ExpressionKind.characterClass:
      case ExpressionKind.notPredicate:
        return false;
      case ExpressionKind.literal:
        final literal = node as LiteralExpression;
        return literal.text.length > 1;
      case ExpressionKind.capture:
      case ExpressionKind.optional:
        final single = node as SingleExpression;
        return needSaveChForExpression(single.expression, processed);
      case ExpressionKind.oneOrMore:
      case ExpressionKind.zeroOrMore:
        return true;
      case ExpressionKind.nonterminal:
      case ExpressionKind.subterminal:
      case ExpressionKind.terminal:
        final symbol = node as SymbolExpression;
        return needSaveChForExpression(symbol.expression, processed);
      case ExpressionKind.orderedChoice:
        final choice = node as SequenceExpression;
        final expressions = choice.expressions;
        for (final expression in expressions) {
          if (needSaveChForExpression(expression, processed)) {
            return true;
          }
        }

        return false;
      case ExpressionKind.sequence:
        final sequence = node as SequenceExpression;
        final expressions = sequence.expressions;
        var count = 0;
        for (final expression in expressions) {
          switch (expression.kind) {
            case ExpressionKind.andPredicate:
            case ExpressionKind.notPredicate:
              continue;
            default:
          }

          if (needSaveChForExpression(expression, processed)) {
            return true;
          }

          if (count++ > 0) {
            return true;
          }
        }

        return false;
    }

    return true;
  }

  bool willExpressionChangeCharOnFailure(
      Expression node, Set<Expression> processed) {
    if (!processed.add(node)) {
      return true;
    }

    switch (node.kind) {
      case ExpressionKind.andPredicate:
      case ExpressionKind.anyCharacter:
      case ExpressionKind.characterClass:
      case ExpressionKind.literal:
      case ExpressionKind.notPredicate:
        return false;
      case ExpressionKind.capture:
      case ExpressionKind.optional:
      case ExpressionKind.oneOrMore:
      case ExpressionKind.zeroOrMore:
        final single = node as SingleExpression;
        return willExpressionChangeCharOnFailure(single.expression, processed);
      case ExpressionKind.nonterminal:
      case ExpressionKind.subterminal:
      case ExpressionKind.terminal:
        final symbol = node as SymbolExpression;
        return willExpressionChangeCharOnFailure(symbol.expression, processed);
      case ExpressionKind.orderedChoice:
        final choice = node as OrderedChoiceExpression;
        final expressions = choice.expressions;
        for (final expression in expressions) {
          if (willExpressionChangeCharOnFailure(expression, processed)) {
            return true;
          }
        }

        return false;
      case ExpressionKind.sequence:
        final sequence = node as SequenceExpression;
        final expressions = sequence.expressions;
        var count = 0;
        var skipOtional = false;
        for (final expression in expressions) {
          switch (expression.kind) {
            case ExpressionKind.andPredicate:
            case ExpressionKind.notPredicate:
              continue;
            default:
          }

          if (expression.isOptional && skipOtional) {
            continue;
          }

          if (count > 0) {
            return true;
          }

          skipOtional = true;
          count++;
        }

        return false;
    }

    return true;
  }

  bool willSequenceChangePosOnFailure(SequenceExpression node) {
    var count = 0;
    for (final child in node.expressions) {
      switch (child.kind) {
        case ExpressionKind.andPredicate:
        case ExpressionKind.notPredicate:
          continue;
        default:
      }

      if (child.isOptional) {
        if (count == 0) {
          count++;
        }

        continue;
      }

      if (count++ > 0) {
        return true;
      }
    }

    return false;
  }

  void runBlock(List<Code> code, void Function() f) {
    final code$ = this.code;
    this.code = code;
    f();
    this.code = code$;
  }

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    _visitPrefix(node);
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final variable = allocNodeVar(node);
    final methodCall = call$(Members.matchAny);
    addAssignFinalOrExpression(code, variable, methodCall);
    childVariable = variable;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final variable = addNodeVar(code, node);
    final child = node.expression;
    if (variable == null) {
      acceptNode(child, code);
    } else {
      final varStart = addAllocFinal(code, refer(Members.pos));
      acceptNode(child, code);
      code <<
          if$(refer(Members.ok), (code) {
            final arguments = [refer(varStart), refer(Members.pos)];
            final methodCall =
                callMethod(Members.source, 'substring', arguments);
            addAssign(code, variable, () => methodCall);
          });
    }

    childVariable = variable;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final variable = allocNodeVar(node);
    final ranges = <int>[];
    for (final group in node.ranges.groups) {
      ranges.add(group.start);
      ranges.add(group.end);
    }

    if (ranges.length == 2) {
      if (ranges[0] == ranges[1]) {
        final char = ranges[0];
        final arguments = [literal(char), literal(char)];
        final methodCall = call$(Members.matchChar, arguments);
        addAssignFinalOrExpression(code, variable, methodCall);
      } else {
        final start = ranges[0];
        final end = ranges[1];
        final arguments = [literal(start), literal(end)];
        final methodCall = call$(Members.matchRange, arguments);
        addAssignFinalOrExpression(code, variable, methodCall);
      }
    } else {
      final varRange = allocator.alloc();
      code << assignConst(varRange, literalList(ranges));
      final arguments = [refer(varRange)];
      final methodCall = call$(Members.matchRanges, arguments);
      addAssignFinalOrExpression(code, variable, methodCall);
    }

    childVariable = variable;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final variable = allocNodeVar(node);
    final text = node.text;
    if (text.isEmpty) {
      if (variable != null) {
        declareVariable(refer('String?'), variable);
        code << assign(variable, literalString(''));
      }

      code << assign(Members.ok, literalTrue);
    } else if (text.length == 1) {
      final char = text.codeUnitAt(0);
      final methodCall =
          call$(Members.matchChar, [literal(char), literalString(text)]);
      addAssignFinalOrExpression(code, variable, methodCall);
    } else {
      final methodCall = call$(Members.matchString, [literalString(text)]);
      addAssignFinalOrExpression(code, variable, methodCall);
    }

    childVariable = variable;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    _visitPrefix(node);
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final variable = addNodeVar(code, node);
    final child = node.expression;
    void fail(List<Code> code) {
      code << break$;
    }

    if (variable == null) {
      final varCount = allocator.alloc();
      code << assignVar(varCount, literal(0));
      code <<
          while$(literalTrue, (code) {
            acceptNode(child, code);
            generateEpilogue(node, code, null, fail);
            code << refer(varCount).postOp('++').statement;
          });

      code << assign(Members.ok, refer(varCount).notEqualTo(literal(0)));
    } else {
      final list = literalList([], refer(child.resultType));
      final varList = addAllocFinal(code, list);
      code <<
          while$(literalTrue, (code) {
            acceptNode(child, code);
            generateEpilogue(node, code, null, fail);
            final element =
                Utils.getNullCheckedValue(childVariable, child.resultType);
            code << callMethod(varList, 'add', [refer(element)]).statement;
          });

      code <<
          if$(property(varList, 'isNotEmpty'), (code) {
            code << assign(variable, refer(varList));
            code << assign(Members.ok, literalTrue);
          });
    }

    childVariable = variable;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final variable = allocNodeVar(node);
    final child = node.expression;
    acceptNode(child, code);
    addAssignFinal(code, variable, refer(childVariable));
    addAssign(code, Members.ok, () => literalTrue);
    childVariable = variable;
  }

  @override
  void visitSubterminal(SubterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitTerminal(TerminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitZeroOrMore(ZeroOrMoreExpression node) {
    final variable = addNodeVar(code, node);
    final child = node.expression;
    void fail(List<Code> code) {
      code <<
          if$(refer(Members.ok).negate(), (code) {
            code << break$;
          });
    }

    if (variable == null) {
      code <<
          while$(literalTrue, (code) {
            acceptNode(child, code);
            fail(code);
          });

      code << assign(Members.ok, literalTrue);
    } else {
      final list = literalList([], refer(child.resultType));
      final varList = addAllocFinal(code, list);
      code <<
          while$(literalTrue, (code) {
            acceptNode(child, code);
            fail(code);
            final element =
                Utils.getNullCheckedValue(childVariable, child.resultType);
            code << callMethod(varList, 'add', [refer(element)]).statement;
          });

      code <<
          if$(refer(Members.ok).assign(literalTrue), (code) {
            code << assign(variable, refer(varList));
          });
    }

    childVariable = variable;
  }

  void _visitPrefix(PrefixExpression node) {
    final variable = addNodeVar(code, node);
    final child = node.expression;
    final storage = <String, String>{};
    addStoreVar(code, Members.ch, storage);
    addStoreVar(code, Members.pos, storage);
    addStoreVar(code, Members.failPos, storage);
    addStoreVar(code, Members.failStart, storage);
    for (final variable in failures.variables) {
      addStoreVar(code, variable, storage);
    }

    acceptNode(child, code);
    addRestoreVars(code, storage);
    if (node.kind == ExpressionKind.notPredicate) {
      code << assign(Members.ok, refer(Members.ok).negate());
    }

    childVariable = variable;
  }

  void _visitSymbol(SymbolExpression node) {
    final variable = allocNodeVar(node);
    final rule = node.expression.rule;
    final identifier = IdentifierHelper.getRuleIdentifier(rule);
    final methodCall = call$(identifier);
    addAssignFinalOrExpression(code, variable, methodCall);
    childVariable = variable;
  }
}
