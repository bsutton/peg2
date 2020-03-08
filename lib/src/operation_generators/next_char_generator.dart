part of '../../operation_generators.dart';

class NextCharGenerator with OperationUtils {
  void generate(BlockOperation block, SparseBoolList ranges,
      {@required Variable c,
      @required Variable input,
      @required Variable pos}) {
    var hasUnicode = false;
    for (final group in ranges.groups) {
      if (group.start > 0xffff || group.end > 0xfff) {
        hasUnicode = true;
        break;
      }
    }

    if (hasUnicode) {
      final test = lteOp(varOp(c), constOp(0xffff));
      final ternary = ternaryOp(test, constOp(1), constOp(2));
      final assignPos = addAssignOp(varOp(pos), ternary);
      final listAcc = listAccOp(varOp(input), assignPos);
      addAssign(block, varOp(c), listAcc);
    } else {
      final posAssign = preIncOp(varOp(pos));
      final listAcc = listAccOp(varOp(input), posAssign);
      addAssign(block, varOp(c), listAcc);
    }
  }
}
