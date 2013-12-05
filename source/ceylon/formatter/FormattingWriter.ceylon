import ceylon.file { Writer }
import ceylon.collection { MutableList, LinkedList }
import org.antlr.runtime { AntlrToken=Token, TokenStream }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer { lineComment=\iLINE_COMMENT, multiComment=\iMULTI_COMMENT, ws=\iWS } }
import ceylon.formatter.options { FormattingOptions }
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
    
    shared class Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter) {
        
        shared default String text;
        shared default Boolean allowLineBreakBefore;
        shared default Integer? postIndent;
        shared default Integer wantsSpaceBefore;
        shared default Integer wantsSpaceAfter;
        
        shared Boolean allowLineBreakAfter {
            if (exists p = postIndent) { // TODO revisit later (should be allowLineBreakAfter = exists postIndent;)
                return true;
            } else {
                return false;
            }
        }
        shared actual String string => text;
    }    
    class OpeningToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter)
        extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter)
        satisfies OpeningElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual object context satisfies FormattingContext {
            postIndent = outer.postIndent else 0;
        }
    }
    class ClosingToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, context)
            extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter)
            satisfies ClosingElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual FormattingContext context;
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
        Boolean allowLineBreakBefore,
        Integer? postIndent,
        Integer wantsSpaceBefore,
        Integer wantsSpaceAfter,
        FormattingContext? context = null) {
        
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
        if (exists context) {
            t = ClosingToken(tokenText, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, context);
            ret = null;
        } else {
            t = OpeningToken(tokenText, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter);
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
                .split((Character c) => c == '\n')
                .first;
        assert (exists firstLine);
        ret.append(OpeningToken(
            firstLine.trimTrailing((Character c) => c == '\r'),
            true, 0, maxDesire, maxDesire));
        ret.appendAll({
            for (line in current.text
                    .split((Character c) => c == '\n')
                    .rest
                    .filter((String elem) => !elem.empty)
                    .map((String l) => l.trimTrailing((Character c) => c == '\r')))
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
                tokenStack.removeLast();
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
        Integer? endIndex = tokenQueue.indexes((QueueElement e) => e == element).first;
        assert (exists endIndex);
        
        if (exists startIndex) {
            // first case: only affects token queue
            filterQueue(startIndex, endIndex);
        } else {
            // second case: affects token stack and queue
            Integer? stackIndex = tokenStack.indexes((FormattingContext e) => e == element.context).first;
            if (exists stackIndex) {
                for (i in stackIndex..tokenStack.size-1) {
                    tokenStack.removeLast();
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
        if (exists length = options.maxLineLength) {
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
                }
                return false;
            }).first;
        }
        if (exists index) {
            if (!is LineBreak t = tokenQueue[index]) {
                tokenQueue.insert(index, LineBreak());
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
     4. Write indentation – the sum of all `postIndent`s on the [[tokenStack]]
     5. Write the elements: the first token directly, since its context was already
        closed in `3.`, the others [[with context|writeWithContext]]
     6. Write a line break
     
     (Note that there may not appear any line breaks before token `i`.)"
    void writeLine(Integer i) {
        Boolean(QueueElement) isToken = function (QueueElement elem) {
            if (is Token elem) {
                return true;
            }
            return false;
        };
        
        QueueElement? firstToken = tokenQueue[0..i].find(isToken);
        
        if (is ClosingToken firstToken) {
            closeContext0(firstToken);
        }
        
        Integer indentLevel = tokenStack.fold(0,
            (Integer partial, FormattingContext elem) => partial + elem.postIndent);
        countingWriter.write(options.indentMode.indent(indentLevel));
        
        variable Token? previousToken = null;
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
                    writeWithContext(currentToken);
                }
                previousToken = currentToken;
            } else if (is EmptyOpening removing) {
                tokenStack.add(removing.context);
            } else if (is EmptyClosing removing) {
                closeContext0(removing);
            }
            tokenQueue.removeFirst();
        }
        
        countingWriter.writeLine();
    }
    
    "Write a token.
     
     1. Write the token’s text
     2. Context handling:
         1. If [[token]] is a [[OpeningToken]], push its context onto the [[tokenStack]];
         2. if it’s a [[ClosingToken]], [[close|closeContext0]] its context."
    void writeWithContext(Token token) {
        countingWriter.write(token.text);
        
        if (is OpeningToken token) {
            tokenStack.add(token.context);
        } else if (is ClosingToken token) {
            closeContext0(token);
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