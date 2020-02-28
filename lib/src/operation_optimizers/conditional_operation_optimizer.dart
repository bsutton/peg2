part of '../../operation_optimizers.dart';

class ConditionalOperationOptimizer with OperationUtils {
  VariablesStats _stats;

  void optimize(BlockOperation operation, VariablesStats stats) {
    _stats = stats;
    _optimizeBlock(operation);
  }

  void _addElse(ConditionalOperation conditional, BlockOperation fromBlock) {
    if (conditional.ifFalse != null) {
      throw StateError('Unable to add else to conditional');
    }

    final block = BlockOperation();
    conditional.ifFalse = block;
    _appendToBlock(fromBlock, block);
  }

  void _appendToBlock(BlockOperation src, BlockOperation dest) {
    dest.operations.addAll(src.operations);
    _initialize(dest);
  }

  void _combineConditionals(BlockOperation block) {
    final operations = block.operations;
    for (var i = 0; i < operations.length; i++) {
      final loop = getOp<LoopOperation>(operations[i]);
      if (loop != null) {
        _combineConditionals(loop.body);
      }

      final prev = getOp<ConditionalOperation>(operations[i]);
      if (prev == null) {
        continue;
      }

      _combineConditionals(prev.ifTrue);
      if (prev.ifFalse != null) {
        _combineConditionals(prev.ifFalse);
      }

      if (i == operations.length - 1) {
        break;
      }

      final next = getOp<ConditionalOperation>(operations[i + 1]);
      if (next == null) {
        continue;
      }

      if (_optimizeEqualVariables(block, prev, next)) {
        continue;
      }

      if (_optimizeEqualNot(block, prev, next)) {
        continue;
      }

      if (_optimizePotentialIfElse(block, prev, next)) {
        continue;
      }
    }
  }

  bool _hasWritings(BlockOperation block, List<Variable> variables) {
    final stat = _stats.getStat(block);
    for (final variable in variables) {
      final count = stat.getWriteCount(variable);
      if (count > 0) {
        return true;
      }
    }

    return false;
  }

  void _initialize(Operation operation) {
    final operationInitializer = OperationInitializer();
    operationInitializer.initialize(operation);
    final resolver = VariablesUsageResolver();
    resolver.resolve(operation, _stats);
  }

  bool _isBlockEmpty(BlockOperation block) {
    for (final operation in block.operations) {
      if (operation is! NopOperation) {
        return false;
      }
    }

    return true;
  }

  bool _isBlockEndsWithGoto(BlockOperation block) {
    final operations = block.operations;
    for (var i = operations.length - 1; i >= 0; i--) {
      final operation = operations[i];
      switch (operation.kind) {
        case OperationKind.break_:
          //case OperationKind.continue_:
          return true;
        case OperationKind.conditional:
          final cond = getOp<ConditionalOperation>(operation);
          if (_isBlockEndsWithGoto(cond.ifTrue)) {
            return true;
          }

          if (cond.ifFalse != null) {
            if (_isBlockEndsWithGoto(cond.ifFalse)) {
              return true;
            }
          }

          return false;
        case OperationKind.loop:
          final loop = getOp<LoopOperation>(operation);
          return _isBlockEndsWithGoto(loop.body);
        case OperationKind.return_:
          return true;
        case OperationKind.nop:
          continue;
        default:
          return false;
      }
    }

    return false;
  }

  bool _isEqualNot(Operation op1, Operation op2, List<Variable> variables) {
    final unary1 = getOp<UnaryOperation>(op1);
    final unary2 = getOp<UnaryOperation>(op2);
    if (unary1 != null && unary2 != null) {
      if (unary1.kind == OperationKind.not &&
          unary2.kind == OperationKind.not) {
        if (_isEqualVariables(unary1.operand, unary2.operand)) {
          final variable = getOp<VariableOperation>(unary1.operand);
          variables.add(variable.variable);
          return true;
        }
      }
    }

    return false;
  }

  bool _isEqualVariables(Operation op1, Operation op2) {
    final variable1 = getOp<VariableOperation>(op1);
    final variable2 = getOp<VariableOperation>(op1);
    if (variable1 != null && variable2 != null) {
      return variable1.variable == variable2.variable;
    }

    return false;
  }

  bool _isPotentialIfElse(
      Operation op1, Operation op2, List<Variable> variables) {
    final kind1 = op1.kind;
    final kind2 = op2.kind;
    if (kind1 == kind2) {
      return false;
    }

    final ops = [op1, op2];
    final set = <Variable>{};
    for (final op in ops) {
      switch (op.kind) {
        case OperationKind.not:
          final unary = getOp<UnaryOperation>(op);
          final variable = getOp<VariableOperation>(unary.operand);
          if (variable == null) {
            return false;
          }

          set.add(variable.variable);
          break;
        case OperationKind.variable:
          final variable = getOp<VariableOperation>(op);
          set.add(variable.variable);
          break;
        default:
          return false;
      }
    }

    if (set.length != 1) {
      return false;
    }

    variables.addAll(set);
    return true;
  }

  bool _isSimpleBinary(BinaryOperation binary) {
    final kind = binary.kind;
    if (kind != OperationKind.assign) {
      return false;
    }

    if (binary.left.kind != OperationKind.variable) {
      return false;
    }

    switch (binary.right.kind) {
      case OperationKind.constant:
      case OperationKind.variable:
        return true;
      default:
    }

    return false;
  }

  bool _isSimpleBlock(BlockOperation block) {
    final operations = block.operations;
    for (var i = 0; i < operations.length; i++) {
      final operation = operations[i];
      switch (operation.kind) {
        case OperationKind.assign:
          final binary = getOp<BinaryOperation>(operation);
          if (!_isSimpleBinary(binary)) {
            return false;
          }

          break;
        case OperationKind.comment:
          break;
        default:
          return false;
      }
    }

    return true;
  }

  void _optimizeBlock(BlockOperation block) {
    _removeEmptyBlocks(block);
    _removeConditionals(block);
    _combineConditionals(block);
  }

  bool _optimizeEqualNot(BlockOperation block, ConditionalOperation prev,
      ConditionalOperation next) {
    if (prev.ifFalse != null || next.ifFalse != null) {
      return false;
    }

    final prevTest = prev.test;
    final nextTest = next.test;
    final prevBlock = prev.ifTrue;
    final nextBlock = next.ifTrue;
    final variables = <Variable>[];
    if (_isEqualNot(prevTest, nextTest, variables)) {
      if (_isSimpleBlock(prevBlock)) {
        if (!_isBlockEndsWithGoto(prevBlock)) {
          if (!_hasWritings(prevBlock, variables)) {
            _appendToBlock(nextBlock, prevBlock);
            _removeFromBlock(block, [next]);
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _optimizeEqualVariables(BlockOperation block, ConditionalOperation prev,
      ConditionalOperation next) {
    if (prev.ifFalse != null || next.ifFalse != null) {
      return false;
    }

    final prevTest = prev.test;
    final nextTest = next.test;
    final prevBlock = prev.ifTrue;
    final nextBlock = next.ifTrue;
    if (_isEqualVariables(prevTest, nextTest)) {
      if (_isSimpleBlock(prevBlock)) {
        if (!_isBlockEndsWithGoto(prevBlock)) {
          final variable = getOp<VariableOperation>(prev.test);
          if (!_hasWritings(prevBlock, [variable.variable])) {
            _appendToBlock(nextBlock, prevBlock);
            _removeFromBlock(block, [next]);
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _optimizePotentialIfElse(BlockOperation block, ConditionalOperation prev,
      ConditionalOperation next) {
    if (prev.ifFalse != null || next.ifFalse != null) {
      return false;
    }

    final prevTest = prev.test;
    final nextTest = next.test;
    final prevBlock = prev.ifTrue;
    final nextBlock = next.ifTrue;
    final variables = <Variable>[];
    if (_isPotentialIfElse(prevTest, nextTest, variables)) {
      if (_isSimpleBlock(prevBlock)) {
        if (!_isBlockEndsWithGoto(prevBlock)) {
          if (!_hasWritings(prevBlock, variables)) {
            _addElse(prev, nextBlock);
            _removeFromBlock(block, [next]);
            return true;
          }
        }
      }
    }

    return false;
  }

  void _removeConditionals(BlockOperation block) {
    final operations = block.operations;
    for (var i = 0; i < operations.length; i++) {
      final loop = getOp<LoopOperation>(operations[i]);
      if (loop != null) {
        _removeConditionals(loop.body);
      }

      final conditional = getOp<ConditionalOperation>(operations[i]);
      if (conditional != null) {
        _removeConditionals(conditional.ifTrue);
        if (conditional.ifFalse != null) {
          _removeConditionals(conditional.ifFalse);
        }
      }

      if (i == operations.length - 1) {
        break;
      }

      final next = getOp<ConditionalOperation>(operations[i + 1]);
      if (next == null) {
        continue;
      }

      if (next.ifFalse != null) {
        continue;
      }

      final binary = getOp<BinaryOperation>(operations[i]);
      if (binary == null) {
        continue;
      }

      if (binary.kind != OperationKind.assign) {
        continue;
      }

      final left = getOp<VariableOperation>(binary.left);
      if (left == null) {
        continue;
      }

      final right = getOp<ConstantOperation>(binary.right);
      if (right == null) {
        continue;
      }

      if (right.value != true) {
        continue;
      }

      final test = getOp<VariableOperation>(next.test);
      if (test == null) {
        continue;
      }

      if (left.variable != test.variable) {
        continue;
      }

      final nextBlock = next.ifTrue;
      final hasAction = nextBlock.operations
          .where((e) => e.kind == OperationKind.action)
          .isNotEmpty;
      if (hasAction) {
        block.operations.insert(i + 1, nextBlock);
      } else {
        block.operations.insertAll(i + 1, nextBlock.operations);
      }

      _removeFromBlock(block, [next]);
      i--;
    }
  }

  void _removeEmptyBlocks(BlockOperation block) {
    final operations = block.operations;
    for (var i = 0; i < operations.length; i++) {
      final current = operations[i];
      final loop = getOp<LoopOperation>(current);
      if (loop != null) {
        final body = loop.body;
        _removeEmptyBlocks(body);
        if (_isBlockEmpty(body)) {
          _removeFromBlock(block, [loop]);
        }

        continue;
      }

      final conditional = getOp<ConditionalOperation>(current);
      if (conditional != null) {
        final ifTrue = conditional.ifTrue;
        _removeEmptyBlocks(ifTrue);
        final isIfTrueEmpty = _isBlockEmpty(ifTrue);
        final ifFalse = conditional.ifFalse;
        var isIfFalseEmpty = true;
        if (ifFalse != null) {
          _removeEmptyBlocks(ifFalse);
          isIfFalseEmpty = _isBlockEmpty(ifFalse);
        }

        if (isIfTrueEmpty && isIfFalseEmpty) {
          _removeFromBlock(block, [conditional]);
        }

        continue;
      }

      final b = getOp<BlockOperation>(current);
      if (b != null) {
        _removeEmptyBlocks(b);
        if (_isBlockEmpty(b)) {
          _removeFromBlock(block, [b]);
        }

        continue;
      }
    }
  }

  void _removeFromBlock(BlockOperation block, List<Operation> operations) {
    final blockOperations = block.operations;
    for (final operation in operations) {
      final nop = NopOperation();
      final index = blockOperations.indexOf(operation);
      if (index == -1) {
        throw StateError('Unable to remove operation.');
      }

      blockOperations[index] = nop;
    }

    _initialize(block);
  }
}

enum TestResult { ifIf, ifElse }
