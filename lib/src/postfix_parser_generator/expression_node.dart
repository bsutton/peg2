part of '../../postfix_parser_generator.dart';

class ExpressionNode {
  List<ExpressionNode> children = [];

  final Expression expression;

  ExpressionNode(this.expression);

  void addChild(ExpressionNode child) {
    children.add(child);
  }
}
