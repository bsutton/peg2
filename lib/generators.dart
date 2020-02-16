import 'dart:convert';

import 'package:dart_style/dart_style.dart';

import 'analyzers.dart';
import 'code_builder.dart';
import 'expressions.dart';
import 'grammar.dart';
import 'operations.dart';

part 'src/generators/expression_intializer.dart';
part 'src/generators/expression_return_type_resolver.dart';
part 'src/generators/expression_transformation_initializer.dart';
part 'src/generators/last_assigned_result_resolver.dart';
part 'src/generators/operation_initializer.dart';
part 'src/generators/operation_optimizer.dart';
part 'src/generators/operation_replacer.dart';
part 'src/generators/operations_to_code_converter.dart';
part 'src/generators/optional_expression_resolver.dart';
part 'src/generators/parser_class_builder.dart';
part 'src/generators/parser_generator.dart';
part 'src/generators/rules_to_operations_builder.dart';
part 'src/generators/unused_variables_remover.dart';
part 'src/generators/utils.dart';
part 'src/generators/variable_usage_resolver.dart';
