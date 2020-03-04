part of '../../postfix_parser_generator.dart';

class ExpressionNode {
  final Expression expression;

  List<ExpressionNode> children = [];

  ExpressionNode(this.expression);

  void addChild(ExpressionNode child) {
    children.add(child);
  }
}
