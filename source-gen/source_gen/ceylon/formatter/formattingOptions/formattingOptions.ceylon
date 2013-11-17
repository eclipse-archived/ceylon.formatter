{FormattingOption+} formattingOptions = {
    FormattingOption {
        "The indentation mode.";
        "IndentMode"; "indentMode"; /* = */ "Spaces(4)";
    },
    FormattingOption {
        "The maximum line length, or `null` for unlimited line length.";
        "Integer?"; "maxLineLength"; /* = */ "null";
    },
    FormattingOption {
        "The strategy to determine where lines should be broken to accomodate [[maxLineLength]].";
        "LineBreakStrategy"; "lineBreakStrategy"; /* = */ "DumbLineBreaks()";
    },
    FormattingOption {
        "Decide whether to keep an opening brace ('{') on the same line (One True Style)
         or put them on the next line (Allman Style).";
        "Boolean"; "braceOnOwnLine"; /* = */ "false";
    }
};