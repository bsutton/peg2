import 'package:code_builder/code_builder.dart';

import 'expression_helper.dart';
import 'type_helper.dart';

Expression nullCheck(Expression expression, String receiverType) {
  if (isDynamicType(receiverType)) {
    return expression;
  }

  if (isNullableType(receiverType)) {
    return expression;
  }

  return postfixExpression(expression, '!');
}
