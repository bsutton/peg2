// @dart = 2.10
part of '../../parser_generator.dart';

class ExpressionsGenerator extends ExpressionVisitor<void> {
  final VariableAllocator allocator;

  List<Code> code;

  final Map<Expression, IfElseGenerator> _tails = {};

  String variable;

  ExpressionsGenerator({@required this.allocator, @required this.code});

  @override
  void visitAndPredicate(AndPredicateExpression node) {
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    final varCh = allocator.alloc();
    final varPos = allocator.alloc();
    code << assignFinal(varCh, refer(Members.ch));
    code << assignFinal(varPos, refer(Members.pos));
    _acceptNode(child, code);
    if (variable$ == null) {
      //
    } else {
      code << assignFinal(variable$, literalNull);
    }

    code << assign(Members.ch, refer(varCh));
    code << assign(Members.pos, refer(varPos));
    variable = variable$;
  }

  @override
  void visitAnyCharacter(AnyCharacterExpression node) {
    final variable$ = variable;
    variable = null;
    final matchAny = call$(Members.matchAny);
    if (variable$ == null) {
      code << matchAny.statement;
    } else {
      code << assignFinal(variable$, matchAny);
    }

    variable = variable$;
  }

  @override
  void visitCapture(CaptureExpression node) {
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    if (variable$ == null) {
      _acceptNode(child, code);
    } else {
      code << declareVariable(refer('String?'), variable$);
      final varStart = allocator.alloc();
      code << assignFinal(varStart, refer(Members.pos));
      _acceptNode(child, code);
      code <<
          if$(refer(Members.ok), (code) {
            code <<
                assign(
                    variable$,
                    callMethod(Members.source, 'substring',
                        [refer(varStart), refer(Members.pos)]));
          });
    }

    variable = variable$;
  }

  @override
  void visitCharacterClass(CharacterClassExpression node) {
    final variable$ = variable;
    variable = null;
    final ranges = <int>[];
    for (final group in node.ranges.groups) {
      ranges.add(group.start);
      ranges.add(group.end);
    }

    if (ranges.length == 2 && ranges[0] == ranges[1]) {
      final char = ranges[0];
      final matchChar =
          call$(Members.matchChar, [literal(char), literal(char)]);
      if (variable$ == null) {
        code << matchChar.statement;
      } else {
        code << assignFinal(variable$, matchChar);
      }
    } else {
      final varRange = allocator.alloc();
      code << assignConst(varRange, literalList(ranges));
      final matchRange = call$(Members.matchRange, [refer(varRange)]);
      if (variable$ == null) {
        code << matchRange.statement;
      } else {
        code << assignFinal(variable$, matchRange);
      }
    }

    variable = variable$;
  }

  @override
  void visitLiteral(LiteralExpression node) {
    final variable$ = variable;
    variable = null;
    final text = node.text;
    if (text.isEmpty) {
      if (variable$ != null) {
        declareVariable(refer('String?'), variable$);
        code << assign(variable$, literalString(''));
      }

      code << assign(Members.ok, literalTrue);
    } else if (text.length == 1) {
      final char = text.codeUnitAt(0);
      final matchChar =
          call$(Members.matchChar, [literal(char), literalString(text)]);
      if (variable$ == null) {
        code << matchChar.statement;
      } else {
        code << assignFinal(variable$, matchChar);
      }
    } else {
      final matchString = call$(Members.matchString, [literalString(text)]);
      if (variable$ == null) {
        code << matchString.statement;
      } else {
        code << assignFinal(variable$, matchString);
      }
    }

    variable = variable$;
  }

  @override
  void visitNonterminal(NonterminalExpression node) {
    _visitSymbol(node);
  }

  @override
  void visitNotPredicate(NotPredicateExpression node) {
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    final varCh = allocator.alloc();
    final varPos = allocator.alloc();
    code << assignFinal(varCh, refer(Members.ch));
    code << assignFinal(varPos, refer(Members.pos));
    _acceptNode(child, code);
    if (variable$ == null) {
      //
    } else {
      code << assignFinal(variable$, literalNull);
    }

    code << assign(Members.ch, refer(varCh));
    code << assign(Members.pos, refer(varPos));
    code << assign(Members.ok, refer(Members.ok).negate());
    variable = variable$;
  }

  @override
  void visitOneOrMore(OneOrMoreExpression node) {
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    if (variable$ == null) {
      final varCount = allocator.alloc();
      code << assignVar(varCount, literal(0));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            code <<
                if$(refer(Members.ok).negate(), (code) {
                  code << break$;
                });

            code << refer(varCount).postOp('++').statement;
          });

      code << assign(Members.ok, refer(varCount).notEqualTo(literal(0)));
    } else {
      variable = allocator.alloc();
      final returnType = child.returnType;
      final type = _isDynamicType(returnType) ? null : refer(returnType);
      code << assignFinal(variable$, literalList([], type));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);
            code <<
                if$(refer(Members.ok).negate(), (code) {
                  code << break$;
                });

            final element = child.nullCheckedValue(variable);
            code << callMethod(variable$, 'add', [refer(element)]).statement;
          });

      code << assign(Members.ok, property(variable$, 'isNotEmpty'));
    }

    variable = variable$;
  }

  @override
  void visitOptional(OptionalExpression node) {
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    if (variable$ == null) {
      _acceptNode(child, code);
    } else {
      variable = allocator.alloc();
      _acceptNode(child, code);
      code << assignFinal(variable$, refer(variable));
    }

    code << assign(Members.ok, literalTrue);
    variable = variable$;
  }

  @override
  void visitOrderedChoice(OrderedChoiceExpression node) {
    final variable$ = variable;
    variable = null;
    final rule = node.rule;
    final level = node.level;
    final expressions = node.expressions;
    final varCh = allocator.alloc();
    final varPos = allocator.alloc();

    void failure(List<Code> code) {
      if (level == 0 && rule.kind == ProductionRuleKind.terminal) {
        final arguments = <_cb.Expression>[];
        arguments.add(literalString(rule.name));
        code << call$(Members.fail, arguments).statement;
      }
    }

    void restoreState(List<Code> code) {
      code << assign(Members.pos, refer(varPos));
      code << assign(Members.ch, refer(varCh));
    }

    if (variable$ != null && level != 0) {
      final returnType = node.returnType;
      code << declareVariable(refer(returnType + '?'), variable$);
    }

    code << assignFinal(varCh, refer(Members.ch));
    code << assignFinal(varPos, refer(Members.pos));
    if (expressions.length > 1) {
      code <<
          while$(literalTrue, (code) {
            for (var i = 0; i < expressions.length; i++) {
              final child = expressions[i];
              if (variable$ != null) {
                variable = allocator.alloc();
              }

              _acceptNode(child, code);

              code <<
                  if$(refer(Members.ok), (code) {
                    if (variable$ != null) {
                      code << assign(variable$, refer(variable));
                    }

                    code << break$;
                  });

              restoreState(code);
            }

            code << break$;
          });

      failure(code);

      if (level == 0) {
        code << refer(variable$).returned.statement;
      }
    } else {
      final tail = _tails[node.parent] ?? IfElseGenerator(refer(Members.ok));
      final child = expressions[0];
      if (variable$ != null) {
        variable = allocator.alloc();
      }

      _acceptNode(child, code);

      if (variable$ == null) {
        tail.elseCode((code) {
          restoreState(code);
          failure(code);
        });

        if (_tails[node.parent] == null) {
          code.addAll(tail.generate());
        }

        if (level == 0) {
          code << literalNull.returned.statement;
        }
      } else {
        tail.ifCode((code) {
          code << assign(variable$, refer(variable));
        });

        tail.elseCode((code) {
          restoreState(code);
          failure(code);
        });

        if (_tails[node.parent] == null) {
          code.addAll(tail.generate());
        }

        if (level == 0) {
          code << refer(variable$).returned.statement;
        }
      }
    }

    variable = variable$;
  }

  @override
  void visitSequence(SequenceExpression node) {
    final variable$ = variable;
    variable = null;
    final expressions = node.expressions;
    final variables = <String>[];
    final hasAction = node.actionIndex != null;
    final semantic = expressions.where((e) => e.variable != null);
    final code$ = code;
    if (variable$ != null) {
      final returnType = node.returnType;
      code << declareVariable(refer(returnType + '?'), variable$);
    }

    void allocVariable(Expression expression) {
      var needAlloc = false;
      if (hasAction) {
        if (expression.variable != null) {
          needAlloc = true;
        }
      } else {
        if (variable$ != null) {
          if (semantic.isNotEmpty) {
            if (expression.variable != null) {
              needAlloc = true;
            }
          } else {
            if (expression.index == 0) {
              needAlloc = true;
            }
          }
        }
      }

      if (needAlloc) {
        variable = allocator.alloc();
      }

      variables.add(variable);
    }

    if (expressions.length > 1) {
      var needTest = false;
      for (var i = 0; i < expressions.length; i++) {
        variable = null;
        final child = expressions[i];
        allocVariable(child);
        if (needTest) {
          code <<
              if$(refer(Members.ok), (code) {
                this.code = code;
                _acceptNode(child, code);
              });
        } else {
          _acceptNode(child, code);
        }

        needTest = !child.isOptional;
      }
    } else {
      final child = expressions[0];
      allocVariable(child);
      _acceptNode(child, code);
    }

    if (variable$ != null || node.actionIndex != null) {
      void action(List<Code> code) {
        final generator = ActionCodeGenerator(
            code: code,
            sequence: node,
            variable: variable$,
            variables: variables);
        generator.generate();
      }

      if (expressions.last.isOptional) {
        action(code);
      } else {
        code << if$(refer(Members.ok), action);
      }
    }

    code = code$;
    variable = variable$;
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
    final variable$ = variable;
    variable = null;
    final child = node.expression;
    final tail = IfElseGenerator(refer(Members.ok));
    _tails[node] = tail;
    if (variable$ == null) {
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);

            tail.elseCode((code) {
              code << break$;
            });

            code.addAll(tail.generate());
          });
    } else {
      variable = allocator.alloc();
      final returnType = child.returnType;
      final type = _isDynamicType(returnType) ? null : refer(returnType);
      code << assignFinal(variable$, literalList([], type));
      code <<
          while$(literalTrue, (code) {
            _acceptNode(child, code);

            tail.elseCode((code) {
              code << break$;
            });

            code.addAll(tail.generate());

            final element = child.nullCheckedValue(variable);
            code << callMethod(variable$, 'add', [refer(element)]).statement;
          });
    }

    code << assign(Members.ok, literalTrue);

    variable = variable$;
  }

  void _acceptNode(Expression node, List<Code> code) {
    _runBlock(code, () => node.accept(this));
  }

  bool _isDynamicType(String type) {
    return type == 'dynamic' || type == 'dynamic?';
  }

  void _runBlock(List<Code> code, void Function() f) {
    final code$ = this.code;
    this.code = code;
    f();
    this.code = code$;
  }

  void _visitSymbol(SymbolExpression node) {
    final variable$ = variable;
    variable = null;
    final rule = node.expression.rule;
    final identifier = Utils.getRuleIdentifier(rule);
    final invoke = call$(identifier);
    if (variable$ == null) {
      code << invoke.statement;
    } else {
      code << assignFinal(variable$, invoke);
    }

    variable = variable$;
  }
}
