part of '../../common_generators.dart';

class OneOrMoreOperationGenerator extends OperationGenerator {
  final OperationGenerator child;

  OneOrMoreOperationGenerator(this.child);

  @override
  void generate(OperationGeneratorContext context) {
    final block = context.block;
  }
} 

abstract class OperationGenerator {
  void generate(OperationGeneratorContext context);
}

class OperationGeneratorContext {
  BlockOperation block;

  Variable initialChar;

  Variable initialPos;

  VariableAllocator va;

  OperationGeneratorVariables variables;

  OperationGeneratorContext copy([bool clear = false]) {
    final result = OperationGeneratorContext();
    if (!clear) {
      result.initialChar = initialChar;
      result.initialPos = initialPos;
    }

    result.va = va;
    result.variables = variables;
    return result;
  }
}

abstract class OperationGeneratorVariables {
  //
}
