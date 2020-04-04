part of '../../common_generators.dart';

class RangesOperationGenerator with OperationUtils {
  void generateConditional(BlockOperation block, Variable c, SparseList ranges,
      void Function(BlockOperation) ifTrue,
      [void Function(BlockOperation) ifFalse]) {
    final test = generateTest(c, ranges);
    addIfElse(block, test, ifTrue, ifFalse);
  }

  Operation generateTest(Variable variable, SparseList ranges) {
    final list = SparseBoolList();
    for (final range in ranges.groups) {
      final group = GroupedRangeList(range.start, range.end, true);
      list.addGroup(group);
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
