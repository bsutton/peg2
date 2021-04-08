// @dart = 2.10

import 'package:code_builder/code_builder.dart'
    hide literalString, Expression, ExpressionVisitor, LiteralExpression;
import 'package:code_builder/code_builder.dart' as _cb;
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart' hide literal;
import 'package:peg2/expressions.dart';

import 'grammar.dart';
import 'src/code_builder_extensions/code_builder_extensions.dart';

part 'src/parser_generator/action_code_generator.dart';
part 'src/parser_generator/expressions_generator.dart';
part 'src/parser_generator/members.dart';
part 'src/parser_generator/parser_class_generator.dart';
part 'src/parser_generator/parser_generator.dart';
part 'src/parser_generator/parser_generator_options.dart';
part 'src/parser_generator/production_rule_name_generator.dart';
part 'src/parser_generator/utils.dart';
part 'src/parser_generator/variable_allocator.dart';
