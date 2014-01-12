import ceylon.file { Writer }
import ceylon.collection { MutableList, LinkedList }
import org.antlr.runtime { AntlrToken=Token, TokenStream }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer {
    lineComment=\iLINE_COMMENT,
    multiComment=\iMULTI_COMMENT,
    ws=\iWS,
    stringLiteral=\iSTRING_LITERAL,
    verbatimStringLiteral=\iVERBATIM_STRING
} }
import ceylon.formatter.options { FormattingOptions, Spaces, Tabs, Mixed }
import ceylon.time.internal.math { floorDiv }

"The maximum value that is safe to use as [[FormattingWriter.writeToken]]’s `wantsSpace[Before|After]` argument.
 
 Using a greater value risks inverting the intended result due to overflow."
shared Integer maxDesire = runtime.maxIntegerValue / 2;
"The minimum value that is safe to use as [[FormattingWriter.writeToken]]’s `wantsSpace[Before|After]` argument.
 
 Using a smaller value risks inverting the intended result due to overflow."
shared Integer minDesire = runtime.minIntegerValue / 2;

"Parses a `Boolean` or `Integer` value into a desire in range [[minDesire]]`..`[[maxDesire]].
 
 If [[desire]] is `Integer`, it is clamped to that range; if it’s `Boolean`, the returned
 value is [[minDesire]] for `false` and [[maxDesire]] for `true`."
shared Integer desire(Boolean|Integer desire) {
    if (is Integer desire) {
        return max({minDesire, min({maxDesire, desire})});
    } else if (is Boolean desire) { // TODO unnecessary if here
        if (desire) {
            return maxDesire;
        } else {
            return minDesire;
        }
    }
    // unreachable
    return 0;
}

shared class Indent(shared Integer level) { }
shared abstract class NoLineBreak() of noLineBreak { }
shared object noLineBreak extends NoLineBreak() { }

"Used in [[FormattingWriter.fastForward]]."
abstract class Stop() of stopAndConsume|stopAndDontConsume { shared formal Boolean consume; }
"Stop fast-forwarding and [[consume|org.antlr.runtime::IntStream.consume]] the current token."
see(`value stopAndDontConsume`)
object stopAndConsume extends Stop() { consume = true; }
"Stop fast-forwarding and *don’t* consume the current token."
see(`value stopAndConsume`)
object stopAndDontConsume extends Stop() { consume = false; }

"Writes out tokens, respecting certain indentation settings and a maximum line width.
 
 Each token written with the [[writeToken]] method is stored in a buffer. As soon as enough tokens
 are present to decide where a line break should occur, the entire line is written out to the
 underlying [[writer]] and the tokens are removed from the buffer. This can also be forced at any
 time with the [[nextLine]] method.
 
 Indentation stacks over the tokens: Each token can specify by how many levels the tokens following
 it should be indented. Such a token opens a [[FormattingContext]], which is then returned by
 `writeToken`. The context can later be closed with another token by passing it to the `writeToken`
 method, which will remove the context and all the contexts on top of it from the context stack.
 The indentation level of a line is the sum of the indentation levels of all contexts on the stack.
 
 You can get a `FormattingContext` not associated with any tokens from the [[openContext]]
 method; this is useful if you only have a closing token, but no opening token: for example, the
 semicolon terminating a statement should clearly close some context, but there is no special
 token which opens that context.
 
 You can also close a `FormattingContext` without a token with the [[closeContext]] method."
shared class FormattingWriter(TokenStream? tokens, Writer writer, FormattingOptions options) {
    
    shared interface FormattingContext {
        shared formal Integer postIndent;
    }
      
    interface Element of OpeningElement|ClosingElement {
        shared formal FormattingContext context;
    }
    interface OpeningElement satisfies Element {}
    interface ClosingElement satisfies Element {}
    
    shared abstract class Empty() of EmptyOpening|EmptyClosing {}
    class EmptyOpening() extends Empty() satisfies OpeningElement {
        shared actual object context satisfies FormattingContext {
            postIndent = 0;
        }
    }    
    class EmptyClosing(context) extends Empty() satisfies ClosingElement {
        shared actual FormattingContext context;
    }
    
    shared class Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine = 0, alignSkip = 0) {
        
        shared default String text;
        shared default Boolean allowLineBreakBefore;
        shared default Integer? postIndent;
        shared default Integer wantsSpaceBefore;
        shared default Integer wantsSpaceAfter;
        """The character position of the first character of the token in its line.
           Analogous to [[AntlrToken.charPositionInLine]].
           
           Example:
           ~~~ceylon
           print ( "hello,
                        world");
           ~~~
           Here, the `charPositionInLine` of the string token is 8, so 8 whitespace
           characters will be removed from each subsequent line. After that, padding
           occurs, producing an output like this:
           ~~~ceylon
           print("hello,
                      world");
           ~~~
           where the first 6 spaces are alignment, then comes one space from [[alignSkip]],
           and then come 4 spaces that are part of the string.
           """
        see (`value alignSkip`)
        shared default Integer charPositionInLine;
        """If [[text]] has several lines, the subsequent lines will be aligned to
           the [[alignSkip]]<sup>th</sup> character of the first line;
           in other words, this determines how many characters from the first line
           are skipped when the subsequent lines are aligned.
           
           Example values: `1` for multi-line string literals (to exclude the initial quote),
           `3` for multi-line verbatim string literals (to exclude the initial quotes).
           ~~~
           print("first line
                  here’s where we have to align
                 aligning here is a syntax error");
           ~~~
           To determine how much whitespace has to be trimmed from the subsequent lines before
           they are padded to be aligned to the first line, [[charPositionInLine]] is used.
           """
        see (`value charPositionInLine`)
        shared default Integer alignSkip;
        
        shared Boolean allowLineBreakAfter => postIndent exists;
        shared actual String string => text;
    }    
    class OpeningToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine = 0, alignSkip = 0)
        extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine, alignSkip)
        satisfies OpeningElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual Integer charPositionInLine;
        shared actual Integer alignSkip;
        shared actual object context satisfies FormattingContext {
            postIndent = outer.postIndent else 0;
        }
    }
    class ClosingToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, context, charPositionInLine = 0, alignSkip = 0)
            extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine, alignSkip)
            satisfies ClosingElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual FormattingContext context;
        shared actual Integer charPositionInLine;
        shared actual Integer alignSkip;
    }
    
    shared class LineBreak() {}
    
    shared alias QueueElement => Token|Empty|LineBreak;
    
    "The `tokenQueue` holds all tokens that have not yet been written."
    variable MutableList<QueueElement> tokenQueue = LinkedList<QueueElement>();
    "The `tokenStack` holds all tokens that have been written, but whose context has not yet been closed."
    MutableList<FormattingContext> tokenStack = LinkedList<FormattingContext>();
    
    Integer tabWidth => 4; // TODO see ceylon/ceylon-spec#866
    "Keeps track of the length of the line that is currently being written.
     
     The width of a tab character is [[tabWidth]]."
    object countingWriter satisfies Writer {
        
        variable Integer m_CurrentWidth = 0; // TODO “don’t ever write code like this in Ceylon”... how else can I hide the setter?
        shared Integer currentWidth => m_CurrentWidth;
        
        shared actual void destroy() => writer.destroy();
        
        shared actual void flush() => writer.flush();
        
        shared actual void write(String string) {
            [String*] lines = [*string.split(Character.equals('\n'))];
            writer.write(lines.first else "");
            for (line in lines.rest) {
                writer.writeLine();
                m_CurrentWidth = 0;
                writer.write(line);
            }
            if (string.endsWith("\n")) {
                writer.writeLine();
                m_CurrentWidth = 0;
            } else {
                for (char in lines.last else "") {
                    if (char == '\t') {
                        m_CurrentWidth = (m_CurrentWidth % tabWidth == 0)
                            then m_CurrentWidth + tabWidth
                            else (floorDiv(m_CurrentWidth, tabWidth) + 1) * tabWidth;
                    } else {
                        m_CurrentWidth += 1;
                    }
                }
            }
        }
        
        shared actual void writeLine(String line) {
            writer.writeLine(line);
            m_CurrentWidth = 0;
        }
    }
    
    "Remembers if anything was ever enqueued."
    variable Boolean isEmpty = true;
    
    "Write a token, respecting [[FormattingOptions.maxLineLength]] and non-AST tokens (comments).
     
     First, fast-forward the token stream until [[token]] is reached, writing out
     any comment tokens; then, put the `token`’s text into the token queue and
     check if a line can be written out.
     
     This method should always be used to write any tokens."
    shared FormattingContext? writeToken(
        AntlrToken|String token,
        Indent|NoLineBreak beforeToken = Indent(0),
        Indent|NoLineBreak afterToken = Indent(0),
        Integer|Boolean spaceBefore = 0,
        Integer|Boolean spaceAfter = 0,
        FormattingContext? context = null) {
        
        Boolean allowLineBreakBefore = beforeToken is Indent;
        Integer? postIndent;
        if (is Indent afterToken) {
            postIndent = afterToken.level;
        } else {
            postIndent = null;
        }
        Integer wantsSpaceBefore = desire(spaceBefore);
        Integer wantsSpaceAfter = desire(spaceAfter);
        
        String tokenText;
        if (is AntlrToken token) {
            tokenText = token.text;
        } else {
            assert (is String token); // the typechecker can't figure that out (yet), see ceylon-spec#74
            tokenText = token;
        }
        fastForward((AntlrToken? current) {
            if (exists current) {
                if (current.type == lineComment || current.type == multiComment) {
                    return fastForwardComment(current);
                } else if (current.type == ws) {
                    return empty;
                } else if (current.text == tokenText) {
                    return {stopAndConsume}; // end fast-forwarding
                } else {
                    // TODO it would be really cool if we could recover here
                    throw Exception("Unexpected token '``current.text``', expected '``tokenText``' instead");
                }
            } else {
                return {stopAndDontConsume}; // end fast-forwarding
            }
        });
        FormattingContext? ret;
        Token t;
        see (`value Token.charPositionInLine`)
        Integer charPositionInLine;
        see (`value Token.alignSkip`)
        Integer alignSkip;
        if (is AntlrToken token) {
            charPositionInLine = token.charPositionInLine;
            if (token.type == stringLiteral) {
                alignSkip = 1; // "string"
            } else if (token.type == verbatimStringLiteral) {
                alignSkip = 3; // """verbatim string"""
            } else {
                alignSkip = 0;
            }
        } else {
            charPositionInLine = 0; // meaningless
            // hack: for now we assume the only multi-line tokens are multi-line string literals,
            // so we use the amount of leading quotes as alignSkip
            assert (is String token);
            alignSkip = token.takingWhile('"'.equals).size;
        }
        if (exists context) {
            t = ClosingToken(tokenText, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, context, charPositionInLine, alignSkip);
            ret = null;
        } else {
            t = OpeningToken(tokenText, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine, alignSkip);
            assert (is OpeningToken t); // ...yeah
            ret = t.context;
        }
        tokenQueue.add(t);
        isEmpty = false;
        writeLines();
        return ret;
    }
    
    "Fast-forward the token stream until the next token contains a line break or isn't hidden, writing out any comment tokens,
     then write a line break.
     
     This is needed to keep a line comment at the end of a line instead of putting it into the next line."
    shared void nextLine() {
        fastForward((AntlrToken? current) {
            if (exists current) {
                if (current.type == lineComment || current.type == multiComment) {
                    return fastForwardComment(current);
                } else if (current.type == ws) {
                    return empty;
                } else {
                    return {LineBreak(), stopAndDontConsume}; // end fast-forwarding
                }
            } else {
                return {LineBreak(), stopAndDontConsume}; // end fast-forwarding
            }
        });
        writeLines();
    }
    
    "[[Fast-forward|fastForward]] a comment token."
    {QueueElement|Stop*} fastForwardComment(AntlrToken current) {
        assert(current.type == lineComment || current.type == multiComment);
        
        SequenceBuilder<QueueElement|Stop> ret = SequenceBuilder<QueueElement|Stop>();
        
        Boolean multiLine = current.type == multiComment && current.text.contains('\n');
        if (multiLine && !isEmpty) {
            // multi-line comments start and end on their own line
            ret.append(LineBreak());
        }
        // now we need to produce the following pattern: for each line in the comment,
        // line, linebreak, line, linebreak, ..., line.
        // notice how there’s no linebreak after the last line, which is why this gets
        // a little ugly...
        String? firstLine = current.text
                .split('\n'.equals)
                .first;
        assert (exists firstLine);
        ret.append(OpeningToken(
            firstLine.trimTrailing('\r'.equals),
            true, 0, maxDesire, maxDesire));
        ret.appendAll({
            for (line in current.text
                    .split('\n'.equals)
                    .rest
                    .filter((String elem) => !elem.empty)
                    .map((String l) => l.trimTrailing('\r'.equals)))
                for (element in {LineBreak(), OpeningToken(line, true, 0, maxDesire, maxDesire)})
                    element
        });
        if (multiLine) {
            ret.append(LineBreak());
        }
        
        return ret.sequence;
    }
    
    "Open a [[FormattingContext]] not associated with any token."
    shared FormattingContext openContext() {
        value noToken = EmptyOpening();
        tokenQueue.add(noToken);
        return noToken.context;
    }
    
    "Close a [[FormattingContext]]."
    // don’t use this internally; use closeContext0 instead.
    shared void closeContext(FormattingContext context) {
        value element = EmptyClosing(context);
        tokenQueue.add(element);
        closeContext0(element);
        if (exists index = tokenStack.indexes((FormattingContext element) => element == context).first) {
            for (i in index..tokenStack.size - 1) {
                tokenStack.deleteLast();
            }
        }
    }
    
    "Close a [[FormattingContext]] associated with a [[QueueElement]].
     
     * If the associated context is still on the queue: Go through the [[tokenQueue]] and between
       the opening element and the closing element (including both), do for each element:
         1. If it’s an [[Empty]], remove it;
         2. If it’s a (subclass of) [[Token]], replace it with a [[Token]].
     * If the associated context isn’t on the queue:
         1. Pop the context and its successors from the [[tokenStack]]
         2. Go through the `tokenQueue` from the beginning until `element` and do the same as above."
    void closeContext0(ClosingElement&QueueElement element) {
        Integer? startIndex = tokenQueue.indexes((QueueElement e) {
            if (is OpeningElement e, e.context == element.context) {
                return true;
            }
            return false;
        }).first;
        Integer? endIndex = tokenQueue.indexes(element.equals).first;
        assert (exists endIndex);
        
        if (exists startIndex) {
            // first case: only affects token queue
            filterQueue(startIndex, endIndex);
        } else {
            // second case: affects token stack and queue
            Integer? stackIndex = tokenStack.indexes(element.context.equals).first;
            if (exists stackIndex) {
                for (i in stackIndex..tokenStack.size-1) {
                    tokenStack.deleteLast();
                }
            }
            filterQueue(0, endIndex);
        }
    }
    
    "Helper method for [[closeContext0]] that filters the tokenQueue as described there."
    void filterQueue(Integer start, Integer end) {
        variable Integer i = 0;
        tokenQueue = LinkedList(tokenQueue.map((QueueElement elem) {
            if (start <= i++ <= end) {
                if (is Empty elem) {
                    return null;
                } else if (is Token elem) {
                    return Token(elem.text, elem.allowLineBreakBefore, elem.postIndent, elem.wantsSpaceBefore, elem.wantsSpaceAfter);
                }
            }
            return elem;
        }).coalesced);
    }
    
    "Write a line if there are enough tokens enqueued to determine where the next line break should occur.
     
     Returns `true` if a line was written, `false` otherwise.
     
     As the queue can contain enough tokens for more than one line, you’ll typically want to call
     [[writeLines]] instead."
    Boolean tryNextLine() {
        if (tokenQueue.empty) {
            return false;
        }
        Integer? index;
        if (is Integer length = options.maxLineLength) {
            index = options.lineBreakStrategy.lineBreakLocation(
                tokenQueue.sequence,
                options.indentMode.indent(
                    tokenStack.fold(0, (Integer partial, FormattingContext elem) => partial + elem.postIndent)
                ).size,
                length);
        } else {
            index = tokenQueue.indexes(function (QueueElement element) {
                if (is LineBreak element) {
                    return true;
                } else if (is Token element, element.text.split('\n'.equals).longerThan(1)) {
                    return true;
                }
                return false;
            }).first;
        }
        if (exists index) {
            if (!is LineBreak t = tokenQueue[index]) {
                if (is Token element = t, element.text.split('\n'.equals).longerThan(1)) {
                    // do *not* insert a LineBreak
                } else {
                    tokenQueue.insert(index, LineBreak());
                }
            }
            writeLine(index);
            return true;
        }
        return false;
    }
    
    "Write out lines as long as there are enough tokens enqueued to determine where the next
     line break should occur."
    void writeLines() {
        while(tryNextLine()) {}
    }
    
    "Write `i + 1` tokens from the queue, followed by a line break.
     
     1. Take elements `0..i` from the queue (making the formerly `i + 1`<sup>th</sup> token
        the new first token)
     2. Determine the first token in that range
     3. If the first token is a [[ClosingToken]], [[close|closeContext]] its context
     4. [[Write indentation|writeIndentation]]
     5. Write the elements:
         * If the last element contains more than one line: [[write]] all tokens directy,
           then [[handle|handleContext]] their contexts
         * otherwise write only the first token directly, since its context was already
           closed in `3.`, and write the others [[with context|writeWithContext]]
     6. If the last element isn’t multi-line: write a line break
     
     (Note that there may not appear any line breaks before token `i`.)"
    void writeLine(Integer i) {
        QueueElement? firstToken = tokenQueue[0..i].find((QueueElement elem) => elem is Token);
        
        if (is ClosingToken firstToken) {
            closeContext0(firstToken);
        }
        
        writeIndentation();
        
        variable Token? previousToken = null;
        "The elements we have to handle later in case we’re writing a multi-line token"
        value elementsToHandle = SequenceBuilder<QueueElement>();
        "The function that handles elements. If the last token is a multi-line token,
         it [[writes|write]] tokens directly and adds the elements to [[elementsToHandle]].
         otherwise it writes tokens [[with context|writeWithContext]] and opens/closes
         [[EmptyOpenings|EmptyOpening]]/[[-Closings|EmptyClosing]]."
        Anything(QueueElement) elementHandler;
        Boolean hasMultiLineToken;
        if (is Token lastToken = tokenQueue[i], lastToken.text.split('\n'.equals).longerThan(1)) {
            hasMultiLineToken = true;
        } else {
            hasMultiLineToken = false;
        }
        if (hasMultiLineToken) {
            elementHandler = function(QueueElement elem) {
                if (is Token t = elem) {
                    write(t);
                }
                elementsToHandle.append(elem);
                return null;
            };
        } else {
            elementHandler = function(QueueElement elem) {
                if (is Token t = elem) {
                    writeWithContext(t);
                } else if (is EmptyOpening|EmptyClosing elem) {
                    handleContext(elem);
                }
                return null;
            };
        }
        for (c in 0..i) {
            QueueElement? removing = tokenQueue.first;
            assert (exists removing);
            if (is Token currentToken = removing) {
                if (exists p = previousToken, p.wantsSpaceAfter + currentToken.wantsSpaceBefore >= 0) {
                    countingWriter.write(" ");
                }
                if (exists firstToken, currentToken == firstToken, is ClosingToken currentToken) {
                    // don’t attempt to close this context, we already did that
                    countingWriter.write(currentToken.text);
                } else {
                    elementHandler(currentToken);
                }
                previousToken = currentToken;
            } else if (is EmptyOpening|EmptyClosing removing) {
                elementHandler(removing);
            }
            tokenQueue.deleteFirst();
        }
        for(token in elementsToHandle.sequence) {
            handleContext(token);
        }
        
        if (hasMultiLineToken) {
            // don’t write a line break
        } else {
            countingWriter.writeLine();
        }
    }
    
    "Write indentation – the sum of all `postIndent`s on the [[tokenStack]].
     
     Unless we’re not at the start of a line, which happens after writing a multi-line token
     (e. g. multi-line string literals)."
    void writeIndentation() {
        if (countingWriter.currentWidth > 0) {
            return;
        }
        Integer indentLevel = tokenStack.fold(0,
            (Integer partial, FormattingContext elem) => partial + elem.postIndent);
        countingWriter.write(options.indentMode.indent(indentLevel));
    }
    
    "Write a token.
     
     1. [[write]] the token’s text
     2. [[handle|handleContext]] the token’s context"
    void writeWithContext(Token token) {
        write(token);
        handleContext(token);
    }
    
    "Write the token’s text. If it contains more than one line, pad the subsequent lines.
     
     The column to align to is determined by getting [[countingWriter.currentWidth]]
     before writing the first line and adding [[token]].[[alignSkip|Token.alignSkip]] to it.
     The subsequent lines are [[trimmed|trimIndentation]], indented with the current indentation
     level (see [[tokenStack]]) using [[options]]`.`[[indentMode|FormattingOptions.indentMode]],
     then aligned to the column with spaces."
    void write(Token token) {
        "The column where the text was originally aligned to."
        Integer sourceColumn = token.charPositionInLine + token.alignSkip;
        "The column where we want to align the text to."
        Integer targetColumn = countingWriter.currentWidth + token.alignSkip;
        {String*} lines = token.text.split{
            splitting = '\n'.equals;
            groupSeparators = false; // keep empty lines
        };
        String? firstLine = lines.first;
        "The token must not be empty"
        assert (exists firstLine);
        countingWriter.write(firstLine);
        for (line in lines.rest) {
            countingWriter.writeLine();
            writeIndentation();
            while (countingWriter.currentWidth < targetColumn) {
                // TODO this is horribly inefficient
                countingWriter.write(" ");
            }
            countingWriter.write(trimIndentation(line, sourceColumn));
        }
    }
    
    "Removes [[column]] columns of whitespace from [[line]].
     
     The width of a tab is taken from the [[options]], or defaults to `4`
     if the options don’t define a tab width in [[indentMode|FormattingOptions.indentMode]]."
    String trimIndentation(String line, column) {
        variable Integer column;
        Integer tabWidth;
        value indentMode = options.indentMode;
        switch (indentMode)
        case (is Tabs) {
            tabWidth = indentMode.width;
        }
        case (is Spaces) {
            tabWidth = 4;
        }
        case (is Mixed) {
            tabWidth = indentMode.tabs.width;
        }
        String trimmedLine = line.trimLeading((Character elem) {
            if (column > 0) {
                if (elem == '\t') {
                    column -= tabWidth;
                } else if (elem.whitespace) {
                    column -= 1;
                } else {
                    return false;
                }
                return true;
            }
            return false;
        });
        String paddedLine = " ".repeat(-column) + trimmedLine;
        return paddedLine;
    }
    
    "If [[element]] is an [[OpeningElement]], push its context onto the [[tokenStack]];
     if it’s a [[ClosingElement]], [[close|closeContext0]] its context."
    void handleContext(QueueElement element) {
        if (is OpeningElement element) {
            tokenStack.add(element.context);
        } else if (is ClosingElement element) {
            closeContext0(element);
        }
    }
    
    "Fast-forward the token stream.
     
     Each token is sent to [[tokenConsumer]], and all non-null [[QueueElement]]s in the
     return value are added to the queue. A [[Stop]] element will stop fast-forwarding;
     its [[consume|Stop.consume]] will determine if the last token is
     [[consumed|TokenStream.consume]] or not.
     
     The `tokenConsumer` only gets `null` tokens if [[tokens]] is null."
    void fastForward({QueueElement|Stop*}(AntlrToken?) tokenConsumer) {
        variable AntlrToken? currentToken;
        variable Integer i;
        if (exists tokens) {
            i = tokens.index();
            currentToken = tokens.get(i);
        } else {
            currentToken = null;
            i = -1;
        }
        variable {QueueElement|Stop*} resultTokens = tokenConsumer(currentToken);
        variable Boolean hadStop = false;
        while (!hadStop) {
            for (QueueElement|Stop element in resultTokens) {
                if (is QueueElement element) {
                    tokenQueue.add(element);
                } else {
                    assert (is Stop element);
                    hadStop = true;
                    if (element.consume, exists tokens) {
                        tokens.consume();
                    }
                    break;
                }
            } else {
                if (exists tokens) {                    
                    tokens.consume();
                    currentToken = tokens.get(++i);
                }
                resultTokens = tokenConsumer(currentToken);
            }
        }
    }
    
    "Enqueue a line break if the last queue element isn’t a line break, then flush the queue."
    shared void close() {
        if (!isEmpty) {
            QueueElement? lastElement = tokenQueue.findLast(function (QueueElement elem) {
                if (is EmptyOpening elem) {
                    return false;
                }
                return true;
            });
            if (exists lastElement, !is LineBreak lastElement) {
                tokenQueue.add(LineBreak());
            }
            writeLines();
        }
    }
}
