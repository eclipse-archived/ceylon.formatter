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
         
         For example: `void foo(String bar)` vs `void foo(String bar) `
         
         You can set this to an `Integer` instead of a `Boolean` for finer-grained control over
         the space; `true` means the same as [[ceylon.formatter::maxDesire]], and `false` means
         the same as [[ceylon.formatter::minDesire]].";
        "Boolean|Integer"; "spaceAfterParamListClosingParen"; /* = */ "-10";
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
        "All|{String*}"; "inlineAnnotations"; /* = */ """{ "abstract", "actual", "annotation", "default", "final", "formal", "native", "optional", "shared", "variable" }""";
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
        """The formatting style for import statements.
           
           * [[singleLine]]
           ~~~
           import java.lang { Thread, JString=String, Runtime { runtime } }
           ~~~
           
           * [[multiLine]]
           ~~~
           import java.lang {
               Thread,
               JString=String,
               Runtime {
                   runtime
               }
           }
           ~~~""";
        "ImportStyle"; "importStyle"; /* = */ "multiLine";
    },
    FormattingOption {
        """Decide if there should be spaces around the equals sign ('=') of an import alias, that is
           ~~~
           import java.lang { JString=String }
           // vs
           import java.lang { JString = String }
           ~~~""";
        "Boolean"; "spaceAroundImportAliasEqualsSign"; "false";
    },
    FormattingOption {
        "The range of line breaks allowed before a line comment (`// comment`).";
        "Range<Integer>"; "beforeLineCommentLineBreaks"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a line comment (`// comment`).
         
         Note that the minimum value of the range must be `> 0`;
         allowing having no line breaks after a line comment would obviously produce syntactically invalid code.";
        "Range<Integer>"; "afterLineCommentLineBreaks"; /* = */ "1..3";
    },
    FormattingOption {
        "The range of line breaks allowed before a single-line multi comment (`/* comment */`).";
        "Range<Integer>"; "beforeSingleCommentLineBreaks"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a single-line multi comment (`/* comment */`).";
        "Range<Integer>"; "afterSingleCommentLineBreaks"; /* = */ "0..3";
    },
    FormattingOption {
        "The range of line breaks allowed before a multi-line comment (`/* comment... \\n ... \\n comment */`).";
        "Range<Integer>"; "beforeMultiCommentLineBreaks"; /* = */ "1..3";
    },
    FormattingOption {
        "The range of line breaks allowed after a multi-line comment (`/* comment... \\n ... \\n comment */`).";
        "Range<Integer>"; "afterMultiCommentLineBreaks"; /* = */ "1..3";
    },
    FormattingOption {
        "The range of line breaks allowed in a type parameter list.";
        "Range<Integer>"; "typeParameterListLineBreaks"; /* = */ "0..1";
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
        """Decide whether there should be a space before the opening parenthesis of a for clause.
           
           For example: `for (c in "text") { ... }` vs `for(c in "text") { ... }`""";
        "Boolean"; "spaceBeforeForOpeningParenthesis"; /* = */ "true";
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
        """Decide whether there should be a space before the opening parenthesis of an if clause.
           
           For example: `if ('c' in "text") { ... }` vs `if('c' in "text") { ... }`""";
        "Boolean"; "spaceBeforeIfOpeningParenthesis"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether, in the case of an error, the formatter should attempt to recover and
           continue or immediately exit.
           
           This is mostly for internal use; in the finished formatter, there shouldn’t be any errors
           when formatting syntactically valid code.""";
        "Boolean"; "failFast"; /* = */ "false";
    },
    FormattingOption {
        """Decide whether there should be a space before a try-with-resources resource list.
           
           For example: `try (w = file.Writer()) { ... }` vs `try(w = file.Writer()) { ... }`""";
        "Boolean"; "spaceBeforeResourceList"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether there should be a space before a `catch` variable.
           
           For example: `catch (Exception e) { ... }` vs `catch(Exception e) { ... }`""";
        "Boolean"; "spaceBeforeCatchVariable"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether there should be a space before the opening parenthesis of a while clause.
           
           For example: `while (bool)` vs `while(bool)`""";
        "Boolean"; "spaceBeforeWhileOpeningParenthesis"; /* = */ "true";
    },
    FormattingOption {
        """Decide whether there should be a space after the comma in a type argument or parameter list.
           
           For example: `Map<Key,Value>` vs `Map<Key, Value>`""";
        "Boolean"; "spaceAfterTypeArgOrParamListComma"; /* = */ "false";
    },
    FormattingOption {
        """By how many levels the `extends` and `satisfies` should be indented.
           
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
        "Integer"; "extendsSatisfiesPreIndent"; /* = */ "2";
    },
    FormattingOption {
        "If [[true]], print timing information to standard error.
         The output is purely informational and its format may change at any time without notice;
         it should not be used in scripts or something similar.";
        "Boolean"; "time"; /* = */ "false";
    },
    FormattingOption {
        """Decide how linebreaks after specifier expression’s main tokens should be handled.
           
           * [[stack]]:
           ~~~
           Html html =>
               Html {
                   head = ...;
                   body = ...;
               }
           ~~~
           * [[addIndentBefore]]:
           ~~~
           Html html =>
                   Html {
               head = ...;
               body = ...;
           }
           ~~~
           The Eclipse IDE’s “Correct Indentation” action produces [[addIndentBefore]].
           See [#37](https://github.com/lucaswerkmeister/ceylon.formatter/issues/37) for more information.
           
           To clarify: this option only applies if you have a line break directly after the `=` or `=>` token.
           Both
           ~~~
           Html html
                   => Html {
               head = ...;
               body = ...;
           }
           ~~~
           (line break *before* `=>`) and
           ~~~
           Html html => Html {
               head = ...;
               body = ...;
           }
           ~~~
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
        "Decide whether `else` should be on its own line.
         For example:
         ~~~
         if (something) {
             // ...
         } else {
             // ...
         }
         ~~~
         vs.
         ~~~
         if (something) {
             // ...
         }
         else {
             // ...
         }
         ~~~";
        "Boolean"; "elseOnOwnLine"; /* = */ "false";
    }
};

{Enum+} enums = {
    Enum("Unlimited"),
    Enum("All"),
    Enum("ImportStyle", { "singleLine", "multiLine" }),
    Enum("IndentationAfterSpecifierExpressionStart", { "stack", "addIndentBefore" }),
    Enum("LineBreak", { "os", "lf", "crlf" })
};
