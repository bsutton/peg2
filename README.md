peg2
=======

# Non-nullable implementation. May contain errors, but is already capable of generating itself.

PEG+ (Parsing expression grammar) parser source code generator, command line tool.

Version 0.2.10

This is a slightly modified (extended) version of PEG with support for nonterminal, terminal and subterminal symbols and with the support of the expression "Capture".

### Warning

This software does not contain public API because it is a tool (utility).

### Planned features

All planned improvements and discovered flaws can be found in the "todo.txt" file.

### Activation and usage

Since this software is a command line utility, it requires activation.  
To activate, you must run the command:

```
pub global activate peg2
```

After activation, the utility is ready for use.

Example of use:  

```
pub global run peg2 json.peg
```

Remember to periodically update this software to get the latest version.

### Performance

Test results based on testing data from project https://github.com/miloyip/nativejson-benchmark  
Compared to the parser built into Dart VM.  
A modified grammar of the PEG2 JSON parser is used, with an algorithm for parsing numbers from the Dart VM parser.  

```
Parse 50 times: E:\prj\test_json\bin\data\canada.json
Dart JSON: k: 1.33, 47.25 MB/s, 2271.61 ms (100.00%),
PEG2 JSON: k: 1.00, 62.73 MB/s, 1711.14 ms (75.33%),

Parse 50 times: E:\prj\test_json\bin\data\citm_catalog.json
Dart JSON: k: 1.00, 99.82 MB/s, 825.00 ms (54.90%),
PEG2 JSON: k: 1.82, 54.80 MB/s, 1502.71 ms (100.00%),

Parse 50 times: E:\prj\test_json\bin\data\twitter.json
Dart JSON: k: 1.00, 62.47 MB/s, 433.49 ms (62.96%),
PEG2 JSON: k: 1.59, 39.33 MB/s, 688.53 ms (100.00%),

OS: Microsoft Windows 7 Ultimate 6.1.7601
Kernel: Windows_NT 6.1.7601
Processor (4 core) Intel(R) Core(TM) i5-3450 CPU @ 3.10GHz
```

### Grammar

Grammar consists of production rules.  
Rules are of three types: nonterminal, terminal and subterminal.  
For each type of rule, a naming convention is defined.  

Below are examples of rule naming:  

- Nonterminals: Value, value, someValue2  
- Terminals: 'string', 'end of file', '['  
- Subterminals: @spacing, @SPACING, @Identifier  

### Production rules

Each rule is an ordered choice and consists of a single ordered choice expression (`OrderedChoice`), which consists of parsing variants.  
Each parsing variant is a sequence (`Sequence`) of parsing expressions, each of which, in turn, may consist of other parsing variant expressions (`OrderedChoice`).

Production rules return values. Return types can be specified explicitly or they can be inferred from return types of expressions `OrderedChoice`.  
Return types of `OrderedChoice` expressions, in some cases, can be inferred from return types of `Sequence` expressions.  
Return types of `Sequence` expressions can be inferred from the types of returned results of the expressions involved in the formation of the result.

In the case when a semantic action is used to generate the result, the type of the return value cannot be inferred automatically. In this case, it is recommended to specify the type of the returned result explicitly.

Example of explicitly specifying the type of the return result:

```
bool 'false' =
  "false" @spacing { $$ = false; }
```

### Sequence expression

Each expression generates a result, but the main result is formed by the expression `Sequence`.  
The expression `Sequence` allows you to use semantic actions to forming results.  
In semantic action semantic values (variables) can be used.  

An example of using semantic variables:

```
List<MapEntry<String, dynamic>> Members =
  m:Member n:(',' m:Member)* { $$ = [m, ...n]; }
  ;

MapEntry<String, dynamic> Member =
  k:'string' ':' v:Value { $$ = MapEntry(k, v); }
  ;
```

### Principles for forming the results of a sequence of expressions

Case #1:  
No semantic variables. No semantic action.  
In this case, the return result will be the result of the first expression (`@IDENTIFIER`).

```
'type name' =
  @IDENTIFIER @SPACING
  ;
```

Case #2:  
One semantic variable. No semantic action.  
In this case, the returned result will be the result of the expression stored in the variable (`v`).

```
Json =
  'leading spaces'? v:Value 'end of file'
  ;
```

Case #3:  
Several semantic variables. No semantic action.  
In this case, the returned result will be a list of the results of all expressions stored in all variables (`[k, v]`).

```
KeyAndValue =
  k:'string' ':' v:Value
  ;
```

Case #4:  
Semantic action specified.  
In this case, the returned result must be formed in semantic action and assigned to the special variable "$$".  
Semantic variables will be available for use to forming the result.

```
String 'string' =
  "\"" c:@char* "\"" @spacing { $$ = String.fromCharCodes(c); }
  ;
```

### Capture expression

The expression `Capture` allows you to capture parsed text from the beginning to the end of the expression `Capture`, without having to form the result from the results of child expressions.  
The syntax for this expression is `<e>`, where `e` is any expression, including a sequence of expressions (`Sequence`).  
This is convenient enough for obtaining a parsing result that corresponds to the parsed text and does not require transformations. You just capture the text and that’s all you need to do in this case.

Examples:

```
'library prefix' =
  <[_]? @IDENTIFIER>
  ;
```

```
'globals' =
  "%{" b:<@GLOBALS_BODY*> "}%" @SPACING
  ;
```

### Terminal expressions

Terminal expressions respond directly to parsing the text.  
The following expressions are terminal expressions: `AnyCharacter`, `CharacterClass` and `Literal`.  
They can consume any character, a character from a specified range, or text, respectively.  
Terminal expressions cannot be used directly in nonterminal rules.

### A little more words about production rules

#### Nonterminal rules

Nonterminal parsing rules are the high level of parsing.  
They can consist of nonterminal and terminal rules, combined by any expressions.  
Nonterminal parsing rules cannot contain terminal expressions such as `AnyCharacter`, `CharacterClass` and `Literal`.

#### Terminal rules

Terminal rules, in turn, are the low level of parsing. They can consist of subtermial rules and terminal expressions such as `AnyCharacter`, `CharacterClass` and `Literal`.  

#### Subterminal rules

Subterminal rules are a sublevel of the low level, which is essentially intended to simplify the writing of grammar, by transferring the most commonly used low-level parsing procedures to the subterminal rules. They can consist of subterminal rules and terminal expressions.

To be continued...
