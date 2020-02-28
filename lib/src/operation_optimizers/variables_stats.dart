part of '../../operation_optimizers.dart';

class VariablesStat {
  final Operation parent;

  Map<Variable, int> readings = {};

  final VariablesStats stats;

  Map<Variable, int> writings = {};

  VariablesStat(this.parent, this.stats);

  void addReadCount(Variable variable, int count) {
    count += getReadCount(variable);
    setReadCount(variable, count);
  }

  void addWriteCount(Variable variable, int count) {
    count += getWriteCount(variable);
    setWriteCount(variable, count);
  }

  int getReadCount(Variable variable) {
    var count = readings[variable];
    count ??= 0;
    return count;
  }

  int getWriteCount(Variable variable) {
    var count = writings[variable];
    count ??= 0;
    return count;
  }

  void setReadCount(Variable variable, int count) {
    final prev = getReadCount(variable);
    if (count == 0) {
      readings.remove(variable);
    } else {
      readings[variable] = count;
    }

    final delta = count - prev;
    final parentStat = _getParentStat();
    if (parentStat != null) {
      parentStat.addReadCount(variable, delta);
    }
  }

  void setWriteCount(Variable variable, int count) {
    final prev = getReadCount(variable);
    if (count == 0) {
      writings.remove(variable);
    } else {
      writings[variable] = count;
    }

    final delta = count - prev;
    final parentStat = _getParentStat();
    if (parentStat != null) {
      parentStat.addWriteCount(variable, delta);
    }
  }

  VariablesStat _getParentStat() {
    if (parent.parent == null) {
      return null;
    }

    return stats.getStat(parent.parent);
  }
}

class VariablesStats {
  final Map<Operation, VariablesStat> _data = {};

  VariablesStat getStat(Operation operation) {
    if (operation == null) {
      throw ArgumentError.notNull('operation');
    }

    var stat = _data[operation];
    if (stat == null) {
      stat = VariablesStat(operation, this);
      _data[operation] = stat;
    }

    return stat;
  }

  VariablesStat getVarDeclStat(Variable variable) {
    if (variable.frozen) {
      return null;
    }

    final declaration = variable.declaration;
    if (declaration == null) {
      return null;
    }

    final declarationParent = declaration.parent;
    if (declarationParent == null) {
      return null;
    }

    final stat = getStat(declarationParent);
    return stat;
  }
}
