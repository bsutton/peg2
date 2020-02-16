peg2
=======

PEG+ (Parsing expression grammar) parser source code generator, command line tool.

Version 0.1.5

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
To be continued...
