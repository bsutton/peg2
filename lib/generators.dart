// @dart = 2.10
import 'dart:math';

import 'package:code_builder/code_builder.dart'
    hide literalString, Expression, ExpressionVisitor, LiteralExpression;
import 'package:code_builder/code_builder.dart' as _cb;
import 'package:dart_style/dart_style.dart';
import 'package:lists/lists.dart';
import 'package:meta/meta.dart' hide literal;
import 'package:peg2/expressions.dart';
import 'package:peg2/utils.dart';

import 'grammar.dart';
import 'src/code_builder_extensions/code_builder_extensions.dart';

part 'src/generators/action_code_generator.dart';
part 'src/generators/bit_flag_generator.dart';
part 'src/generators/class_members.dart';
part 'src/generators/expression_generator_base.dart';
part 'src/generators/identifier_helper.dart';
part 'src/generators/members.dart';
part 'src/generators/parser_class_generator_base.dart';
part 'src/generators/parser_generator_base.dart';
part 'src/generators/production_rule_name_generator.dart';
