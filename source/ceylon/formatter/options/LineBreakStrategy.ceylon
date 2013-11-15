import ceylon.formatter { ... }

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

class DumbLineBreaks() extends LineBreakStrategy() {

    shared actual Integer? lineBreakLocation(FormattingWriter.QueueElement[] elements, Integer offset, Integer maxLineLength) {
        variable Integer currentLength = offset;
        variable Integer index = 0;
        variable FormattingWriter.Token? previousToken = null;
        "*Ugly* hack because `!exists previousToken` is not a normal expression" // TODO revisit this later
        variable Boolean hasPreviousToken = false;
        while (currentLength <= maxLineLength || !hasPreviousToken) {
            FormattingWriter.QueueElement? element = elements[index];
            switch (element)
            case (is FormattingWriter.Token) {
                currentLength += element.text.size;
                if (exists p = previousToken, p.wantsSpaceAfter + element.wantsSpaceBefore >= 0) {
                    currentLength++; // space between tokens
                }
                previousToken = element;
                hasPreviousToken = true;
            }
            case (is FormattingWriter.LineBreak) {
                return index;
            }
            case (is Null) {
                // we’ve reached  the end of the queue
                break;
            }
            else {
                // do nothing
            }
            index++;
        }
        index--; // we increased it one time too much in the loop
        if (index >= elements.size || currentLength < maxLineLength) {
            return null;
        }
        if (!is FormattingWriter.LineBreak l = elements[index], index == 0) {
            // ensure that we don’t write a neverending chain of empty lines because the first token is already too long
            return 1;
        }
        return index;
    }
}