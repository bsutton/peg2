part of '../../common_generators.dart';

class RangesOperationGenerator with OperationUtils {
  void generateConditional(BlockOperation block, Variable c, SparseList ranges,
      bool canMacthEof, void Function(BlockOperation) ifTrue,
      [void Function(BlockOperation) ifFalse]) {
    final test = generateTest(c, ranges, canMacthEof);
    addIfElse(block, test, ifTrue, ifFalse);
  }

  Operation generateTest(
      Variable variable, SparseList ranges, bool canMacthEof) {
    final list = SparseBoolList();
    for (final src in ranges.groups) {
      final dest = GroupedRangeList<bool>(src.start, src.end, true);
      list.addGroup(dest);
    }

    Operation op(int start, int end) {
      if (start == end) {
        return eqOp(varOp(variable), constOp(start));
      } else {
        final left = gteOp(varOp(variable), constOp(start));
        final right = lteOp(varOp(variable), constOp(end));
        return landOp(left, right);
      }
    }

    if (canMacthEof) {
      final group = GroupedRangeList<bool>(0x10ffff + 1, 0x10ffff + 1, true);
      list.addGroup(group);
    }

    final groups = list.groups.toList();
    final first = groups.first;
    var result = op(first.start, first.end);
    for (var i = 1; i < groups.length; i++) {
      final group = groups[i];
      final right = op(group.start, group.end);
      result = lorOp(result, right);
    }

    return result;
  }
}
