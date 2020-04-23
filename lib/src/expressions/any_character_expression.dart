part of '../../expressions.dart';

class AnyCharacterExpression extends Expression {
  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitAnyCharacter(this);
  }

  @override
  String toString() {
    return '.';
  }
}
