part of '../../operation_transformers.dart';

class OperationReplacer extends SimpleOperationVisitor {
  Operation _from;

  Operation _to;

  void replace(Operation from, Operation to, VariablesStats stats) {
    _from = from;
    _to = to;
    VariablesStat stat;
    if (stats != null) {
      stat = stats.getStat(from);
    }

    final parent = from.parent;
    parent.accept(this);
    final operationInitializer = OperationInitializer();
    operationInitializer.initialize(to);
    if (stats != null) {
      final parentStat = stats.getStat(parent);
      final readings = stat.readings;
      for (final key in readings.keys) {
        final count = readings[key];
        parentStat.addReadCount(key, -count);
      }

      final writings = stat.writings;
      for (final key in writings.keys) {
        final count = writings[key];
        parentStat.addWriteCount(key, -count);
      }

      final variablesUsageResolver = VariablesUsageResolver();
      variablesUsageResolver.resolve(to, stats);
    }
  }

  @override
  void visit(Operation node) {
    _replace(node);
  }

  void _replace(Operation node) {
    if (!node.replaceChild(_from, _to)) {
      throw StateError('Unable to replace operation, operation not found');
    }
  }
}
