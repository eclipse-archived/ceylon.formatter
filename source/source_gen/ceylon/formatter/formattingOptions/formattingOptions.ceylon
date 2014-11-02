/*
 NOTE:
 
 The documentation is also used by --help=options
 and printed _unformatted_ there.
 Please use indented code blocks instead of fenced ones,
 since the former are easier to read in plain text.
 */
{FormattingOption+} formattingOptions = {
    FormattingOption {
        "The indentation mode.";
        "IndentMode"; "indentMode"; /* = */ "Spaces(4)";
    },
    FormattingOption {
        "The maximum line length, or [[unlimited]].";
        "Integer|Unlimited"; "maxLineLength"; /* = */ "unlimited";
    },
    FormattingOption {
        "The strategy to determine where lines should be broken to accomodate [[maxLineLength]].";
        "LineBreakStrategy"; "lineBreakStrategy"; /* = */ "DefaultLineBreaks()";
    },
    FormattingOption {
        "Decide whether to keep an opening brace ('{') on the same line (One True Style)
         or put them on the next line (Allman Style).";
        "Boolean"; "braceOnOwnLine"; /* = */ "false";
    },
    FormattingOption {
        "Decide whether to put a space before the opening parenthesis ('(') of a method definition’s
         parameter list or not.
         
         For example: `void foo(String bar)` vs `void foo (String bar)`";
        "Boolean"; "spaceBeforeParamListOpeningParen"; /* = */ "false";
    },
    FormattingOption {
        "Decide whether to put a space after the opening parenthesis ('(') of a method definition’s
         parameter list or not.
         
         For example: `void foo(String bar)` vs `void foo( String bar)`";
        "Boolean"; "spaceAfterParamListOpeningParen"; /* = */ "false";
    },
    FormattingOption {
        "Decide whether to put a space before the closing parenthesis (')') of a method definition’s
         parameter list or not.
         
         For example: `void foo(String bar)` vs `void foo (String bar )`";
        "Boolean"; "spaceBeforeParamListClosingParen"; /* = */ "false";
    },
    FormattingOption {
        "Decide whether to put a space after the closing parenthesis (')') of a method definition’s
         parameter list or not.
         
         This only applies when the parameter list is followed by a brace
         (as is the case for simple functions and classes).
         If it is instead followed by a fat arrow, a space is always added;
         if it’s followed by a semicolon (formal), or a comma or closing paren
         (parameter list of functional parameter), no space is be added.
         
         For example: `void foo(String bar) {}` vs `void foo(String bar){}`";
        "Boolean"; "spaceAfterParamListClosingParen"; /* = */ "true";
    },
    FormattingOption {
        """Decide which annotations should be on the same line as their declaration.
           
           [[all]] means that all annotations should be on the same line, in other words,
           that line breaking will only occur according to [[lineBreakStrategy]].
           
           If you give an [[Iterable]] instead, a line break will be appended after any annotation
           that it doesn’t contain. For example, the default value will produce:
           
               by ("John Doe")
               throws (`class Anything`)
               shared formal void foo();
           
           where `by` and `throws` are each on a separate line because they are not elements
           of the default value, but `shared` and `formal` are elements of the default value
           and therefore on the same line as the declaration.
           
           If the value of this option is [[empty]], line breaks will be inserted after every
           annotation (no "inline" annotations).
           
           It should be noted that the annotations can look weird if you put "inline" annotations
           before or between "own-line" annotations:
           
               shared by ("John Doe")
               formal throws (`class Anything`)
               void foo();
           
           Don’t do that. (You can already see in this small example how the combination
           "shared by" can be potentially confusing.)""";
        "All|{String*}"; "inlineAnnotations"; /* = */ """{ "abstract", "actual", "annotation", "default", "final", "formal", "late", "native", "optional", "shared", "variable" }""";
    },
    FormattingOption {
        """Decide if there should be a space in front of a positional argument list for a method or class.
           
           A positional argument list is the complement of a named argument list,
           i. e. what you’d probably know as simply an argument list:
           
               process.arguments.filter("--help --usage --version".split().contains);
               //                      '----------positional argument list---------'""";
        "Boolean"; "spaceBeforeMethodOrClassPositionalArgumentList"; /* = */ "false";
    },
    FormattingOption {
        """Decide if there should be a space in front of a positional argument list for an annotation.
           
           A positional argument list is the complement of a named argument list,
           i. e. what you’d probably know as simply an argument list:
           
               process.arguments.filter("--help --usage --version".split().contains);
               //                      '----------positional argument list---------'""";
        "Boolean"; "spaceBeforeAnnotationPositionalArgumentList"; /* = */ "true";
    },
    FormattingOption {
        """The range of line breaks allowed between import elements.
           
           `0..0` is a “forced single-line” style:
           
               import java.lang { Thread, JString=String, Runtime { runtime } }
           
           `0..1` is “freeform” style:
           
               import java.lang {
                   Thread, JString=String,
                   Runtime {
                       runtime
                   }
               }
           
           `1..1` is “forced multi-line” style:
           
               import java.lang {
                   Thread,
                   JString=String,
                   Runtime {
                       runtime
                   }
               }
           
           (Of course, wider ranges like `0..3` are also permitted.)""";
        "Range<Integer>"; "lineBreaksBetweenImportElements"; /* = */ "1..1";
    },
    FormattingOption {
        """Decide if there should be spaces around the equals sign ('=') of an import alias, that is
           
               import java.lang { JString=String }
               // vs
               import java.lang { JString = String }""";
        "Boolean"; "spaceAroundImportAliasEqualsSign"; "false";
    },
    FormattingOption {
        "The range of line breaks allowed before a line comment (`// comment`).";
        "Range<Integer>"; "lineBreaksBeforeLineComment"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a line comment (`// comment`).
         
         Note that the minimum value of the range must be `> 0`;
         allowing having no line breaks after a line comment would obviously produce syntactically invalid code.";
        "Range<Integer>"; "lineBreaksAfterLineComment"; /* = */ "1..3";
    },
    FormattingOption {
        "The range of line breaks allowed before a single-line multi comment (`/* comment */`).";
        "Range<Integer>"; "lineBreaksBeforeSingleComment"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a single-line multi comment (`/* comment */`).";
        "Range<Integer>"; "lineBreaksAfterSingleComment"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed before a multi-line comment (`/* comment... \\n ... \\n comment */`).";
        "Range<Integer>"; "lineBreaksBeforeMultiComment"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a multi-line comment (`/* comment... \\n ... \\n comment */`).";
        "Range<Integer>"; "lineBreaksAfterMultiComment"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed in a type parameter list.";
        "Range<Integer>"; "lineBreaksInTypeParameterList"; /* = */ "0..1";
    },
    FormattingOption {
        "Decide whether there should be a space after the opening brace of a sequence enumeration.
         
         For example: `{ 1, 2, 3 }` vs `{1, 2, 3}`";
        "Boolean"; "spaceAfterSequenceEnumerationOpeningBrace"; /* = */ "true";
    },
    FormattingOption {
        "Decide whether there should be a space before the closing brace of a sequence enumeration.
         
         For example: `{ 1, 2, 3 }` vs `{1, 2, 3}`";
        "Boolean"; "spaceBeforeSequenceEnumerationClosingBrace"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether there should be a space after the opening parenthesis of a value iterator.
           
           For example: `for ( c in "text" ) { ... }` vs `for (c in "text") { ... }`""";
        "Boolean"; "spaceAfterValueIteratorOpeningParenthesis"; /* = */ "false";
    },
    FormattingOption {
        """Decide whether there should be a space before the closing parenthesis of a value iterator.
           
           For example: `for ( c in "text" ) { ... }` vs `for (c in "text") { ... }`""";
        "Boolean"; "spaceBeforeValueIteratorClosingParenthesis"; /* = */ "false";
    },
    FormattingOption {
        """Decide whether, in the case of an error, the formatter should attempt to recover and
           continue or immediately exit.
           
           This is mostly for internal use; in the finished formatter, there shouldn’t be any errors
           when formatting syntactically valid code.""";
        "Boolean"; "failFast"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether there should be a space after the comma in a type argument or parameter list.
           
           For example: `Map<Key,Value>` vs `Map<Key, Value>`""";
        "Boolean"; "spaceAfterTypeArgOrParamListComma"; /* = */ "false";
    },
    FormattingOption {
        """By how many levels `extends`, `satisfies`, `of`, `given`, and `abstracts` should be indented.
           
           For example:
           
               // 2
               class Foo()
                       extends Bar()
                       satisfies Baz {}
               // vs
               // 1
               class Foo()
                   extends Bar()
                   satisfies Baz {}""";
        "Integer"; "indentBeforeTypeInfo"; /* = */ "2";
    },
    FormattingOption {
        """Decide how line breaks after specifier expression’s main tokens should be handled.
           
           * [[stack]]:
                   Html html =>
                       Html {
                           head = ...;
                           body = ...;
                       }
           * [[addIndentBefore]]:
                   Html html =>
                           Html {
                       head = ...;
                       body = ...;
                   }
           
           The Eclipse IDE’s “Correct Indentation” action produces [[addIndentBefore]].
           See [#37](https://github.com/lucaswerkmeister/ceylon.formatter/issues/37) for more information.
           
           To clarify: this option only applies if you have a line break directly after the `=` or `=>` token.
           Both
           
               Html html
                       => Html {
                   head = ...;
                   body = ...;
               }
           
           (line break *before* `=>`) and
           
               Html html => Html {
                   head = ...;
                   body = ...;
               }
           
           (no line break around `=>` at all) are unaffected by this option.""";
        "IndentationAfterSpecifierExpressionStart"; "indentationAfterSpecifierExpressionStart"; /* = */ "addIndentBefore";
    },
    FormattingOption {
        "Decide whether blank lines should be indented or not.";
        "Boolean"; "indentBlankLines"; /* = */ "true";
    },
    FormattingOption {
        "The character(s) used to break lines, or [[os]] to use the operating system’s line breaks.";
        "LineBreak"; "lineBreak"; /* = */ "lf";
    },
    FormattingOption {
        "Decide whether `else` and `catch` should be on its own line.
         For example:
         
             if (something) {
                 // ...
             } else {
                 // ...
             }
         
         vs.
         
             if (something) {
                 // ...
             }
             else {
                 // ...
             }";
        "Boolean"; "elseOnOwnLine"; /* = */ "false";
    },
    FormattingOption {
        "Decide whether there should be spaces around satisfied interfaces and case types.
         For example:
         
             class MyClass()
                     satisfies MyInterface&MyOtherInterface
                     of CaseType1|CaseType2 { ... }
         
         vs.
         
             class MyClass()
                     satisfies MyInterface & MyOtherInterface
                     of CaseType1 | CaseType2 { ... }";
        "Boolean"; "spaceAroundSatisfiesOf"; /* = */ "true";
    },
    FormattingOption {
        "Decide whether there should be a space between
         a control structure keyword and its opening parenthesis.
         
         This applies to the following keywords:
         - `if`
         - `for`
         - `while`
         - `try`, when followed by a resource list
         - `catch`
         - `switch`
         - `case`";
        "Boolean"; "spaceAfterControlStructureKeyword"; /* = */ "true";
    },
    FormattingOption {
        "If true, enforce that binary operators are always surrounded by spaces.
         
         Otherwise, the spaces may be omitted within complex expressions.
         The exact rules for this are too complicated to be documented here,
         but they result in spacing like this:
         
             value sum = 1 + 2 + 3;
             value hollowCubeVolume = w*h*d - iW*iH*iD; // (inner) width/height/depth
             value allEqual = a==b && b==c && c==d;
             value regular = start..end;
             value shifted = start+offset .. end+offset;";
        "Boolean"; "forceSpaceAroundBinaryOp"; /* = */ "false";
    }
};

{Enum+} enums = {
    Enum("Unlimited"),
    Enum("All"),
    Enum("IndentationAfterSpecifierExpressionStart", { "stack", "addIndentBefore" }),
    Enum { "LineBreak"; { "os", "lf", "crlf" }; generate = false; }
};
