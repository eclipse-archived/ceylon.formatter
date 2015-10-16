import ceylon.formatter {
    FormattingWriter
}

"A strategy to break a series of tokens into multiple lines to accomodate a maximum line length."
shared abstract class LineBreakStrategy() {
    
    "Determine where the next line break should occur,
     or return a [[null]] index if no line break should occur (e. g. because there aren’t enough tokens).
     
     If the first element of the returned value `[i, lb]` (**i**ndex, **l**ine **b**reak) exists,
     it means that tokens `0..i` should be taken from the elements and written out;
     if `lb` is [[true]], a [[LineBreak|ceylon.formatter::FormattingWriter.LineBreak]] should be inserted there first.
     
     To clarify, the caller of this method should react to the returned value `[i, lb]` like this:
     
     - If `i` is [[null]], do nothing.
     
     - If `lb` is [[true]], take the elements up to (but not including) `i` and write them out
       (removing them from the queue), then write out a line break.
       
       Equivalently, insert a [[**L**ine**B**reak|ceylon.formatter::FormattingWriter.LineBreak]] into the queue
       at index `i`, then write out the elements up to and including `i`.
       
       Afterwards, the element that was previously `elements[i]` is now the first queued element.
     
     - If `lb` is [[false]], take the elements up to and including `i` and write them out
       (removing them from the queue). (Do not write out an explicit line break.)
       
       Afterwards, the element that was previously `elements[i + 1]` is now the first queued element.
     
     Usually, when an element makes the line too long, its index and [[true]] is returned.
     The [[false]] case is necessary for
     a) existing explicit line breaks, and
     b) multi-line string literals that don’t make the line too long, but still break the line
     (but not with an explicit extra line break)."
    shared formal [Integer?, Boolean] lineBreakLocation(
        "The tokens of the line."
        FormattingWriter.QueueElement[] elements,
        "The initial line length, negated if caused by indentation.
         
         The [[absolute value|Integer.magnitude]] is the initial line length.
         If the value is [[negative|Integer.negative]] or [[zero|Integer.zero]], this line length is indentation only;
         if it’s [[positive|Integer.positive]], it comes from a multi-line token.
         
         The difference between these cases is that after a multi-line token,
         it’s reasonable to immediately insert a line break
         (without writing a single token),
         whereas doing that if the indentation alone exceeds the maximum line length will lead to an infinite loop."
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
