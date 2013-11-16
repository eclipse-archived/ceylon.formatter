import ceylon.formatter { FormattingWriter }
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
        // respect the token’s allowLineBreakBefore/-After
        Integer origIndex = index;
        "Used to determine if we should use [[index]] or [[origIndex]]."
        variable Boolean skippedToken = false;
        while (index > 0) { // TODO revisit later
            if (is FormattingWriter.Token element = elements[index]) {
                if (element.allowLineBreakBefore) {
                    skippedToken = true;
                } else {
                    break;
                }
            }
            if (is FormattingWriter.Token element = elements[index]) {
                if (element.allowLineBreakAfter) {
                    skippedToken = true;
                } else {
                    break;
                }
            }
            index--;
        }
        index++; // we decreased it one time too much in the loop
        if (skippedToken, !is FormattingWriter.LineBreak l = elements[index], index == 0) {
            // same as above, except we return the original index to avoid lots of almost-empty lines
            return origIndex;
        }
        return index;
    }
}
