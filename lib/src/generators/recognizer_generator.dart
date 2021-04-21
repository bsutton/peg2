import 'package:lists/lists.dart';
import 'package:peg2/src/helpers/expression_helper.dart';
import 'package:code_builder/code_builder.dart' show Expression;

class RecognizerGenerator {
  final SparseBoolList list;

  final int maxCount;

  final String variable;

  RecognizerGenerator(
      {required this.list, required this.maxCount, required this.variable});

  Expression? generate() {
    var count = 0;
    final ranges = <int>[];
    Expression test(int start, int end) {
      count++;
      if (start == end) {
        return ref(variable).equalTo(literal(start));
      }

      count++;
      final left = ref(variable).greaterOrEqualTo(literal(start));
      final rigth = ref(variable).lessOrEqualTo(literal(end));
      return left.and(rigth);
    }

    for (final group in list.groups) {
      ranges.add(group.start);
      ranges.add(group.end);
    }

    var result = test(ranges[0], ranges[1]);
    for (var i = 2; i < ranges.length; i += 2) {
      final start = ranges[i];
      final end = ranges[i + 1];
      result = result.or(test(start, end));
    }

    if (count > maxCount) {
      return null;
    }

    return result;
  }
}
