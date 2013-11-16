import ceylon.formatter { FormattingWriter }

"A strategy to break a series of tokens into multiple lines to accomodate a maximum line length."
shared abstract class LineBreakStrategy() {

    "Determine where the next line break should occur, or return `null` if no line break should
     occur (e. g. because there aren’t enough tokens).
     
     If the returned value exists, it denotes the index of the first element in [[elements]]
     that shouldn’t be part of the new line, i. e. the index where a
     [[LineBreak|FormattingWriter.LineBreak]] should be inserted (unless that element already is
     a `LineBreak`)."
    shared formal Integer? lineBreakLocation(
        "The tokens of the line."
        FormattingWriter.QueueElement[] elements,
        "The initial line length (usually indentation)."
        Integer offset,
        "The maximum line length."
        see(`value FormattingOptions.maxLineLength`)
        Integer maxLineLength);
}

shared LineBreakStrategy? parseLineBreakStrategy(String string) {
    if (string == "dumb") {
        return DumbLineBreaks();
    }
    throw Exception("Unknown line breaking strategy '``string``'!");
}
