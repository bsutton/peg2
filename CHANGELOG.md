## 0.1.22

- Fixed bugs in `ExpressionStartCharactersResolver`
- Redesigned class hierarchy
- Added new optimization method: final variables usage optimizer

## 0.1.21

- Redesigned the architecture and structure of generators
- Reworked the production rule methods generator, improved reuse of initial variables in expressions
- Minor improvements of code generators, now generated code is even cleaner ans shorter
- Small changes in the algorithm of the generated expressions
- Fixed bugs in `VariableUsageOptimizer`
- Improved `UnusedVariablesRemover`
- Fixed bugs in `GeneralProductionRulesGenerator.visitSequence()`

## 0.1.20

- Fixed bugs in analyzer `InvocationsResolver`, the analyzer has been reworked

## 0.1.19

- Minor changes (corrections) to the grammar file `peg2.peg`

## 0.1.18

- Removed (as unnecessary) analyzer directive `ignore_for_file: unused_local_variable` from generated code
- Removed (as unnecessary) analyzer directive `ignore_for_file: prefer_final_locals` from generated code
- Reworked and improved error handling system, it has become simpler, clearer, more reliable and a little faster

## 0.1.17

- Improved (changed) algorithm for generating expressions `SequenceExpression` and  `OrderedChoiceExpression`, reduced amount of generated code

## 0.1.16

- Added command line option `--optimize-code`
- Improved failure reporting
- Added new optimizer: `VariableUsageOptimizer`
- Improved optimizer: `UnusedVariablesRemover`
- Improved optimizer: `ConditionalOperationOptimizer`, added functionality to remove empty statement blocks

## 0.1.15

- Fixed bug in generator `AnyCharcterExprtession` with the Unicode character greater then 0xffff

## 0.1.14

- Fixed bug with an increment value of `_pos_`, the length of the Unicode character was not taken into account

## 0.1.12

- Implemented experimental prediction feature, command line option `--predict`
- Added feature: convert terminal calls into inline expressions, command line option `--inline-terminals`
- Added feature: convert all calls into inline expressions, command line option `--inline-all`

## 0.1.11

- Added new resolver: `ExpressionProductivenessResolver`
- Improved performance of the `match` expressions
- Improved failure tracking performance

## 0.1.10

- Memoization algorithm made more optimal

## 0.1.9

- Improved performance of experimental memoization feature

## 0.1.8

- Implemented experimental memoization feature, command line option `--memoize`

## 0.1.7

- Implemented conditional operation optimizer to transform conditional operations

## 0.1.6

- Removed import of `dart:html`. How was it added?

## 0.1.5

- Added feature: convert nonterminal calls into inline expressions, command line option `--inline-nonterminals`
- Added feature: convert subterminal calls into inline expressions, command line option `--inline-subterminals`

## 0.1.4

- Added (experimental) support of NNBD type naming convetion to grammar `peg2.peg`
- Added support of library prefix to grammar `peg2.peg`

## 0.1.3

- Added a small description and instructions for use

## 0.1.2

- Fixed source code according to pub.dev health suggestions

## 0.1.1

- Fixed source code according to pub.dev health suggestions

## 0.1.0

- Initial release
