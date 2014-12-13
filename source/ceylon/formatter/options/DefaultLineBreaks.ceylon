import ceylon.formatter {
    FormattingWriter
}
class DefaultLineBreaks() extends LineBreakStrategy() {
    
    string => "default";
    
    shared actual Integer? lineBreakLocation(FormattingWriter.QueueElement[] elements, Integer offset, Integer maxLineLength) {
        "Only the [[FormattingWriter.Token]] elements from [[elements]].
         
         This allows us to access previous and next tokens directly
         instead of having to deal with non-token elements."
        FormattingWriter.Token[] tokens = [for (elem in elements) if (is FormattingWriter.Token elem) elem];
        
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
                if (exists token = tokens[tokenIndex]) {
                    if (token.text.split(Character.equals('\n')).longerThan(1)) {
                        // multi-line literal
                        assert (exists index = elements.firstIndexWhere(token.equals));
                        return index;
                    }
                    currentLength += token.text.size;
                    if (exists previousToken = tokens[tokenIndex - 1],
                        previousToken.wantsSpaceAfter+token.wantsSpaceBefore >= 0) {
                        currentLength++; // space between tokens
                    }
                    tokenIndex++;
                } else {
                    /*
                     we’ve reached the end of the tokens without exceeding the maxLineLength;
                     return the index of the first LineBreak or null if there isn’t one
                     */
                    return elements.firstIndexWhere((elem) => elem is FormattingWriter.LineBreak);
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
        FormattingWriter.Token? tokenAtIndex = tokens[tokenIndex];
        if (is Null tokenAtIndex) {
            /*
             we’ve reached the end of the tokens without finding a suitable token;
             return the index of the first LineBreak or null if there isn’t one
             */
            return elements.firstIndexWhere((elem) => elem is FormattingWriter.LineBreak);
        }
        else {
            
            /*
             3. find the element index from the token index
             go through elements until we encounter token
             (or a LineBreak).
             */
            
            variable Integer elementIndex = 0;
            while (exists element = elements[elementIndex], element != tokenAtIndex) {
                if (is FormattingWriter.LineBreak element) {
                    return elementIndex;
                }
                elementIndex++;
            }
            
            if (elementIndex >= elements.size) {
                /*
                 we’ve reached the end of the tokens without finding a suitable token;
                 return the index of the first LineBreak or null if there isn’t one
                 */
                return elements.firstIndexWhere((elem) => elem is FormattingWriter.LineBreak);
            }
            return elementIndex;
        }
    }
}
