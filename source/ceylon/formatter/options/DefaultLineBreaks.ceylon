import ceylon.formatter {
    FormattingWriter {
        QueueElement=QueueElement,
        Token=Token,
        LineBreak=LineBreak
    }
}
// TODO don’t fully qualify FormattingWriter.QueueElement, Token, LineBreak (ceylon/ceylon-spec#989)
class DefaultLineBreaks() extends LineBreakStrategy() {
    
    shared actual Integer? lineBreakLocation(FormattingWriter.QueueElement[] elements, Integer offset, Integer maxLineLength) {
        "Only the [[FormattingWriter.Token]] elements from [[elements]].
         
         This allows us to access previous and next tokens directly
         instead of having to deal with non-token elements."
        FormattingWriter.Token[] tokens = elements.filter((FormattingWriter.QueueElement elem) => elem is FormattingWriter.Token).collect((FormattingWriter.QueueElement element) {
                assert (is FormattingWriter.Token element);
                return element;
            });
        
        /*
         1. find the best location to break a line, without respect
            to existing line breaks and allowSpace{Before,After} settings
         */
        
        variable Integer currentLength = offset;
        "The index of the token in [[tokens]] whose index in [[elements]]
         we’re going to return."
        variable Integer tokenIndex = 0;
        if (currentLength > maxLineLength) {
            tokenIndex = 1;
        } else {
            while (currentLength <= maxLineLength) {
                FormattingWriter.Token? token = tokens[tokenIndex];
                if (exists token) {
                    if (token.text.split(Character.equals('\n')).longerThan(1)) {
                        // multi-line literal
                        Integer? elementIndex = elements.firstIndexWhere(token.equals);
                        assert (exists elementIndex);
                        return elementIndex;
                    }
                    currentLength += token.text.size;
                    if (exists previousToken = tokens[tokenIndex - 1],
                        previousToken.wantsSpaceAfter + token.wantsSpaceBefore >= 0) {
                        currentLength++; // space between tokens
                    }
                    tokenIndex++;
                } else {
                    /*
                     we’ve reached the end of the tokens without exceeding the maxLineLength;
                     return the index of the first LineBreak or null if there isn’t one
                     */
                    return elements.firstIndexWhere((FormattingWriter.QueueElement elem) => elem is LineBreak);
                }
            }
            if (tokenIndex > 1) {
                tokenIndex--; // we incremented it one time too much in the loop
            }
        }
        
        /*
         2. respect allowSpace{Before,After} settings
            go back until we encounter an index where the tokens before and after
            allow a line break; we hit the beginning of the tokens, search in the
            other direction; if we then hit the end of the tokens, return the index
            of the first existing LineBreak, else null.
         */
        
        Integer origTokenIndex = tokenIndex;
        while (exists token = tokens[tokenIndex], exists previousToken = tokens[tokenIndex - 1],
            !(previousToken.allowLineBreakAfter && token.allowLineBreakBefore)) {
            tokenIndex--;
        }
        if (tokenIndex <= 0) {
            // search in the other direction
            tokenIndex = origTokenIndex;
            while (exists token = tokens[tokenIndex], exists nextToken = tokens[tokenIndex + 1],
                !(token.allowLineBreakAfter && nextToken.allowLineBreakBefore)) {
                tokenIndex++;
            }
            tokenIndex++; // we want the index of the second token of the pair
        }
        FormattingWriter.Token? token = tokens[tokenIndex];
        if (is Null token) {
            /*
             we’ve reached the end of the tokens without finding a suitable token;
             return the index of the first LineBreak or null if there isn’t one
             */
            return elements.firstIndexWhere((FormattingWriter.QueueElement elem) => elem is LineBreak);
        }
        assert (exists token); // TODO revisit, unnecessary assert
        
        /*
         3. find the element index from the token index
            go through elements until we encounter token
            (or a LineBreak).
         */
        
        variable Integer elementIndex = 0;
        while (exists element = elements[elementIndex], element != token) {
            if (is LineBreak element) {
                return elementIndex;
            }
            elementIndex++;
        }
        
        if (elementIndex >= elements.size) {
            /*
             we’ve reached the end of the tokens without finding a suitable token;
             return the index of the first LineBreak or null if there isn’t one
             */
            return elements.firstIndexWhere((FormattingWriter.QueueElement elem) => elem is LineBreak);
        }
        return elementIndex;
    }
}
