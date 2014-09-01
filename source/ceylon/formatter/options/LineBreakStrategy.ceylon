import ceylon.formatter {
    FormattingWriter
}

"A strategy to break a series of tokens into multiple lines to accomodate a maximum line length."
shared abstract class LineBreakStrategy() {
    
    "Determine where the next line break should occur, or return `null` if no line break should
     occur (e. g. because there aren’t enough tokens).
     
     If the returned value `i` exists, it means that tokens `0..i` should be taken from the elements
     and written out; if the element at that index does not contain a line break, a
     [[LineBreak|ceylon.formatter::FormattingWriter.LineBreak]] should be inserted there first.
     
     To clarify:
     
     * If `elements[i]` is neither a [[LineBreak|ceylon.formatter::FormattingWriter.LineBreak]] nor a
       [[Token|ceylon.formatter::FormattingWriter.Token]] with more than one line,
       a `LineBreak` should be inserted at `elements[i]`;
     * then (this is independent of the “if” above), `elements[0..i]` should be removed and written."
    shared formal Integer? lineBreakLocation(
        "The tokens of the line."
        FormattingWriter.QueueElement[] elements,
        "The initial line length (usually indentation)."
        Integer offset,
        "The maximum line length."
        see (`value FormattingOptions.maxLineLength`)
        Integer maxLineLength);
    
    "A string representation of the line break strategy, suitable
     for being saved and loaded via [[saveProfile]] and [[loadProfile]].
     [[parseLineBreakStrategy]] should be able to parse it."
    see (`function parseLineBreakStrategy`)
    shared actual formal String string;
}

shared LineBreakStrategy? parseLineBreakStrategy(String string) {
    if (string == "default") {
        return DefaultLineBreaks();
    }
    throw Exception("Unknown line breaking strategy '``string``'!");
}
