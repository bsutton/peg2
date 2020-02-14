part of '../../expressions.dart';

class AnyCharacterExpression extends Expression {
  @override
  dynamic accept(ExpressionVisitor visitor) {
    return visitor.visitAnyCharacter(this);
  }

  @override
  String toString() {
    return '.';
  }
}
