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
           annotation.
           
           It should be noted that the annotations can look weird if you put "inline" annotations
           before or between "own-line" annotations:
           
               shared by ("John Doe")
               formal throws (`class Anything`)
               void foo();
           
           Don’t do that. (You can already see in this small example how the combination
           "shared by" can be potentially confusing.)""";
        "None|{String*}"; "inlineAnnotations"; /* = */ """{ "abstract", "actual", "annotation", "default", "final", "formal", "native", "optional", "shared", "variable" }""";
    }
};

{Enum+} enums = {
    Enum("Unlimited"),
    Enum("None")
};
