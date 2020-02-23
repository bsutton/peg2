part of '../../expressions.dart';

class AnyCharacterExpression extends Expression {
  @override
  void accept(ExpressionVisitor visitor) {
    visitor.visitAnyCharacter(this);
  }

  @override
  String toString() {
    return '.';
  }
}
