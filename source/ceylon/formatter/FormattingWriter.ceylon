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

"The maximum value that is safe to use as [[FormattingWriter.writeToken]]’s `space[Before|After]` argument.
 
 Using a greater value risks inverting the intended result due to overflow."
shared Integer maxDesire = runtime.maxIntegerValue / 2;
"The minimum value that is safe to use as [[FormattingWriter.writeToken]]’s `space[Before|After]` argument.
 
 Using a smaller value risks inverting the intended result due to overflow."
shared Integer minDesire = runtime.minIntegerValue / 2 + 1;

"Parses a `Boolean` or `Integer` value into a desire in range [[minDesire]]`..`[[maxDesire]].
 
 If [[desire]] is `Integer`, it is clamped to that range; if it’s `Boolean`, the returned
 value is [[minDesire]] for `false` and [[maxDesire]] for `true`."
shared Integer desire(Boolean|Integer desire) {
    if (is Integer desire) {
        return max{minDesire, min{maxDesire, desire}};
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
shared Range<Integer> noLineBreak = 0..0;

"Used in [[FormattingWriter.fastForward]]."
abstract class Stop() of stopAndConsume|stopAndDontConsume { shared formal Boolean consume; }
"Stop fast-forwarding and [[consume|org.antlr.runtime::IntStream.consume]] the current token."
see(`value stopAndDontConsume`)
object stopAndConsume extends Stop() { consume = true; }
"Stop fast-forwarding and *don’t* consume the current token."
see(`value stopAndConsume`)
object stopAndDontConsume extends Stop() { consume = false; }

"Writes tokens to an underlying [[writer]], respecting certain formatting settings and a maximum line width.
 
 The [[FormattingWriter]] manages the following aspects:
 
 * Indentation
 * Line Breaking
 * Spacing
 
 Additionally, it also writes comments if a [[token stream|tokens]] is given.
 
 # Indentation
 
 Two [[Indent]]s are associated with each token: one before the token, and one after it.
 Warning: they are not symmetrical!
 
 **The `indentAfter` of a token** introduces a *context* (instance of [[FormattingContext]]) that is
 pushed onto a *context stack* when the token is written. The indentation of each line is the
 sum of all indentation currently on the context stack. When a context is closed, the context
 and all contexts on top of it are removed from the context stack.
 
 A context can be closed in two ways:
 1. By associating it with a token. For example, you would say that a closing brace `}` closes the
    context of the corresponding opening brace `{`: The block has ended, and subsequent lines should
    no longer be indented as if they were still part of the block. Tokens that close another token’s
    context do not open a context of their own.
 2. By calling [[closeContext]].
 
 You can also obtain a context not associated with any token by calling [[openContext]]. This is
 mostly useful if you have a closing token with no designated opening token: for example, a statement’s
 closing semicolon `;` should close some context, but there is no corresponding token which opens
 that context.
 
 **The `indentBefore` of a token** does *not* introduce any context. It is only applied when a line
 line break has occured immediately before this line, i. e. if it is the first token of its line.
 For example, the member operator `.` typically has an `indentBefore` of `1`: A “call chain”
 `foo.bar.baz` should, if spread across several lines, be indented, but that indentation should not
 stack across multiple member operators.
 
 # Line Breaking
 
 Two [[Integer]] [[ranges|Range]] are associated with each token. One indicates how many line breaks
 may occur before the token, and the other indicates how many may occur after the token. Additionally,
 one may call [[requireAtLeastLineBreaks]] and [[intersectAllowedLineBreaks]] to further restrict
 how many line breaks may occur between two tokens.
 
 The intersection of these ranges for the border between two tokens is then used to determine how
 many line breaks should be written before the token.
 
 * If [[tokens]] exists, then each time a token is written, the token stream is fast-forwarded until
   the token is met (if a token with a different text is met, an exception is thrown). In
   fast-forwarding, the amount of line breaks is counted. After fast-forwarding has finished, the
   number of line breaks that were counted is clamped into the line break range, and this many
   line breaks are written.
 * If [[tokens]] doesn’t exist, then the first element of the range is used (usually the lowest,
   unless the range is [[decreasing|Range.decreasing]]).
 
 Additionally, the [[FormattingWriter]] also breaks lines according to a maximum line length and
 a [[ceylon.formatter.options::LineBreakStrategy]], as determined by [[options]].
 To achieve this, tokens are not directly written to the underlying writer; instead, they are
 added to a *token queue* (not to be confused with the token *stack*, which is used for indentation).
 Each time a token is added, the [[FormattingWriter]] checks if there are enough tokens on the queue
 for the line break strategy to decide where a line break should be placed. Line breaks are allowed
 between tokens if their respecive ranges included at least one value greater than zero (in other
 words, to disallow a line breaks between two tokens, pass a range of `0..0` to either of them).
 When a line break location is known, that line is written and its tokens removed from the queue
 (their contexts are then added to the token stack).
 
 # Spacing
 
 If you’ve made it this far, relax, this is the easiest section :)
 
 Two [[Integer]]s are associated with each token. One indicates the token’s desire to have a space
 before it, the other indicates the desire to have a space after it. When the two tokens are written,
 these integers are added, and if the sum is `>= 0`, then a space is written.
 
 To avoid inverting the intended result by numerical overflow, don’t use values outside the range
 [[minDesire]]`..`[[maxDesire]]. You can also give `false` and `true` to [[writeToken]], which
 are convenient and readable syntax sugar for these two values (`spaceBefore = true`).
 
 # Comments
 
 The fast-forwarding of the token stream (if given) was already mentioned in the “Line Breaking” section.
 If comment tokens are encountered during the fast-forwarding, they are written out like tokens with
 
 * `spaceBefore = maxDesire - 1, spaceAfter = maxDesire - 1`
 * `indentBefore = Indent(0), indentAfter = Indent(0)`
 * `linebreaksBefore, linebreaksAfter` as determined by the [[options]]
     * [[beforeLineCommentLineBreaks|FormattingOptions.beforeLineCommentLineBreaks]] and
       [[afterLineCommentLineBreaks|FormattingOptions.afterLineCommentLineBreaks]] for `// line comments`
     * [[beforeSingleCommentLineBreaks|FormattingOptions.beforeSingleCommentLineBreaks]] and
       [[afterSingleCommentLineBreaks|FormattingOptions.afterSingleCommentLineBreaks]] for `/* single-line multi comments */`
     * [[beforeMultiCommentLineBreaks|FormattingOptions.beforeMultiCommentLineBreaks]] and
       [[afterMultiCommentLineBreaks|FormattingOptions.afterMultiCommentLineBreaks]] for
       ~~~
       /*
          multi-line
          comments
        */
       ~~~"
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
    
    shared class Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine = 0, alignSkip = 0, preIndent = 0) {
        
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
        "The amount of levels to indent before this token.
         This is only effective if this is the first token in its line,
         and the only affects this line."
        shared default Integer preIndent;
        
        shared Boolean allowLineBreakAfter => postIndent exists;
        shared actual String string => text;
    }    
    class OpeningToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine = 0, alignSkip = 0, preIndent = 0)
        extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine, alignSkip, preIndent)
        satisfies OpeningElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual Integer charPositionInLine;
        shared actual Integer alignSkip;
        shared actual Integer preIndent;
        shared actual object context satisfies FormattingContext {
            postIndent = outer.postIndent else 0;
        }
    }
    class ClosingToken(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, context, charPositionInLine = 0, alignSkip = 0, preIndent = 0)
            extends Token(text, allowLineBreakBefore, postIndent, wantsSpaceBefore, wantsSpaceAfter, charPositionInLine, alignSkip, preIndent)
            satisfies ClosingElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Integer? postIndent;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual FormattingContext context;
        shared actual Integer charPositionInLine;
        shared actual Integer alignSkip;
        shared actual Integer preIndent;
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
    
    "Must not allow no line breaks after a line comment, breaks syntax"
    assert (min(options.afterLineCommentLineBreaks) > 0);
    
    Boolean equalsOrSameText(QueueElement self)(QueueElement? other) {
        if (exists other) {
            if (self == other) {
                return true;
            }
            if (is Token self, is Token other, self.text == other.text) {
                return true;
            }
        }
        return false;
    }
    
    variable Range<Integer> currentlyAllowedLinebreaks = 0..0;
    
    variable Integer? givenLineBreaks = tokens exists then 0;
    
    "Intersect the range of allowed line breaks between the latest token and the next one to be [[written|writeToken]]
     with the given range."
    see (`function requireAtLeastLineBreaks`)
    shared void intersectAllowedLineBreaks(Range<Integer> other,
        "If [[true]], [[FormattingWriter.fastForward]] the token stream before intersecting the line breaks.
         This makes a difference if there are comments between the latest and the next token; with fast-forwarding,
         the intersection will be applied between the comments and the next token, while without it, the intersection
         will be applied between the latest token and the comments."
        Boolean fastForwardFirst = true) {
        if (fastForwardFirst) {
            fastForward((AntlrToken? current) {
                if (exists current) {
                    if (current.type == lineComment || current.type == multiComment) {
                        value result = fastForwardComment(current, givenLineBreaks);
                        givenLineBreaks = result[0];
                        return result[1];
                    } else if (current.type == ws) {
                        value lineBreaks = current.text.count('\n'.equals);
                        if (exists g=givenLineBreaks) {
                            givenLineBreaks = g + lineBreaks;
                        } else {
                            givenLineBreaks = lineBreaks;
                        }
                        return empty;
                    } else {
                        return {stopAndDontConsume}; // end fast-forwarding
                    }
                } else {
                    return {stopAndDontConsume}; // end fast-forwarding
                }
            });
        }
        value inc1 = currentlyAllowedLinebreaks.decreasing then currentlyAllowedLinebreaks.reversed else currentlyAllowedLinebreaks;
        value inc2 = other.decreasing then other.reversed else other;
        value intersect = max{inc1.first, inc2.first}..min{inc1.last, inc2.last};
        if (intersect.decreasing) {
            assert (false); // TODO
        }
        currentlyAllowedLinebreaks = currentlyAllowedLinebreaks.decreasing then intersect.reversed else intersect;
    }
    "Require at leasts [[limit]] line breaks between the latest token and the next one to be [[written|writeToken]]."
    see (`function intersectAllowedLineBreaks`)
    shared void requireAtLeastLineBreaks(Integer limit,
        "If [[true]], [[FormattingWriter.fastForward]] the token stream before intersecting the line breaks.
         This makes a difference if there are comments between the latest and the next token; with fast-forwarding,
         the intersection will be applied between the comments and the next token, while without it, the intersection
         will be applied between the latest token and the comments."
        see (`function intersectAllowedLineBreaks`)
        Boolean fastForwardFirst = true)
            => intersectAllowedLineBreaks(limit..runtime.maxIntegerValue, fastForwardFirst);
    
    "Based on [[currently allowed line breaks|currentlyAllowedLinebreaks]]
     and the [[given amount of line breaks|givenLineBreaks]],
     decide how many line breaks should be printed.
     
     The current implementation will clamp the given line breaks into the allowed range
     or use the first value of the allowed range if they’re null."
    Integer lineBreakAmount(Integer? givenLineBreaks) {
        if (is Integer givenLineBreaks) {
            return min{max{givenLineBreaks, min(currentlyAllowedLinebreaks)}, max(currentlyAllowedLinebreaks)};
        } else {
            return currentlyAllowedLinebreaks.first;
        }
    }
    
    "Add a single token, then try to write out a line.
     
     See the [[class documentation|FormattingWriter]] for more information on the token model
     and how the various parameters of a token interact.
     
     All arguments (except [[token]], of course) default to a “save to ignore” / “don’t care” value."
    shared FormattingContext? writeToken(
        token,
        context = null,
        indentBefore = Indent(0),
        indentAfter = Indent(0),
        linebreaksBefore = 0..1,
        linebreaksAfter = 0..1,
        spaceBefore = 0,
        spaceAfter = 0,
        optional = false,
        tokenInStream = token) {
        
        // parameters
        "The token."
        AntlrToken|String token;
        "The context that this token closes. If this value isn’t `null`, then this token will not
         itself open a new context, and the method will therefore return `null`."
        FormattingContext? context;
        "The indentation that should be applied to a line if this token is the first of its line."
        Indent indentBefore;
        "The indentation that should be applied to all subsequent lines until the token’s context
         is closed."
        Indent indentAfter;
        "The amount of line breaks that is allowed before this token."
        see (`value noLineBreak`)
        Range<Integer> linebreaksBefore;
        "The amount of line breaks that is allowed after this token."
        Range<Integer> linebreaksAfter;
        "Whether to put a space before this token.
         
         [[true]] and [[false]] are sugar for [[maxDesire]] and [[minDesire]], respectively."
        see (`value maxDesire`, `value minDesire`)
        Integer|Boolean spaceBefore;
        "Whether to put a space after this token.
         
         [[true]] and [[false]] are sugar for [[maxDesire]] and [[minDesire]], respectively."
        see (`value maxDesire`, `value minDesire`)
        Integer|Boolean spaceAfter;
        "If the token is marked optional, then it is only written if it also occurs in the
         [[token stream|tokens]].
         
         This should be rarely used, as there are typically not many optional tokens; one example
         are the angle brackets for grouping types: they are required in complicated types like
         `{<Key->Value>*} map`, but around `<String> name`, they are optional.
         
         (If the token stream doesn’t exist, the token is currently always written; however,
         in the future a more sophisticated method to avoid writing too many unnecessary optional
         tokens might be added.)"
        Boolean optional;
        "The token that is expected to occur in the token stream for this token.
         
         In virtually all cases, this is the same as [[token]]; however, for identifiers, the
         `\\i`/`\\I` that is sometimes part of the code isn’t included in the token text, so
         in this case you would pass, for example, `\\iVALUE` as [[token]] and `value` as
         [[tokenInStream]],"
        AntlrToken|String tokenInStream;
        
        "Line break count range must be nonnegative"
        assert (linebreaksBefore.first >= 0 && linebreaksBefore.last >= 0);
        "Line break count range must be nonnegative"
        assert (linebreaksAfter.first >= 0 && linebreaksAfter.last >= 0);
        
        // desugar
        Integer spaceBeforeDesire;
        Integer spaceAfterDesire;
        String tokenText;
        String tokenInStreamText;
        Boolean allowLineBreakBefore;
        Integer preIndent;
        Integer? postIndent;
        spaceBeforeDesire = desire(spaceBefore);
        spaceAfterDesire = desire(spaceAfter);
        if (is AntlrToken token) {
            tokenText = token.text;
        } else {
            assert (is String token); // the typechecker can't figure that out (yet), see ceylon-spec#74
            tokenText = token;
        }
        if (is AntlrToken tokenInStream) {
            tokenInStreamText = tokenInStream.text;
        } else {
            assert (is String tokenInStream); // the typechecker can't figure that out (yet), see ceylon-spec#74
            tokenInStreamText = tokenInStream;
        }
        allowLineBreakBefore = linebreaksBefore.any(0.smallerThan);
        preIndent = allowLineBreakBefore then indentBefore.level else 0;
        postIndent = linebreaksAfter.any(0.smallerThan) then indentAfter.level;
        
        // look for optional token
        // if it’s not there, return immediately
        // the following sections will perform irreversible changes (intersect currentlyAllowedLineBreaks etc.)
        if (optional, exists tokens) { // TODO if no token stream, we’ll always write optionals. Be smarter!
            variable value i = 1;
            try {
                while (exists currentToken = tokens.\iLT(i++)) {
                    if (currentToken.type in {lineComment, multiComment, ws}) {
                        continue;
                    }
                    if (currentToken.text == tokenInStreamText) {
                        break;
                    } else {
                        return null;
                    }
                }
            } catch (Exception e) {
                // reached the end of the token stream
                return null;
            }
        }
        
        // handle the part before this token:
        // fast-forward, intersect allowed line breaks, write out line breaks
        intersectAllowedLineBreaks(linebreaksBefore, false);
        fastForward((AntlrToken? current) {
            if (exists current) {
                if (current.type == lineComment || current.type == multiComment) {
                    // we treat comments as regular tokens
                    // just with the difference that their before- and afterToken range isn’t given, but an option instead
                    value result = fastForwardComment(current, givenLineBreaks);
                    givenLineBreaks = result[0];
                    return result[1];
                } else if (current.type == ws) {
                    value lineBreaks = current.text.count('\n'.equals);
                    if (exists g=givenLineBreaks) {
                        givenLineBreaks = g + lineBreaks;
                    } else {
                        givenLineBreaks = lineBreaks;
                    }
                    return empty;
                } else if (current.type == -1) {
                    // EOF
                    return {stopAndDontConsume};
                } else if (current.text == tokenInStreamText) {
                    return {stopAndConsume}; // end fast-forwarding
                } else {
                    value ex = Exception("Unexpected token '``current.text``', expected '``tokenText``' instead");
                    if (options.failFast) {
                        throw ex;
                    } else {
                        ex.printStackTrace();
                        // attempt to recover by just writing out tokens until we find the right one
                        return { OpeningToken {
                            current.text;
                            allowLineBreakBefore = true;
                            postIndent = 0;
                            wantsSpaceBefore = 0;
                            wantsSpaceAfter = 0;
                        } };
                    }
                }
            } else {
                return {stopAndDontConsume}; // end fast-forwarding
            }
        });
        for (i in 0:lineBreakAmount(givenLineBreaks)) {
            tokenQueue.add(LineBreak());
        }
        givenLineBreaks = tokens exists then 0;
        // handle this token:
        // set allowed line breaks, add token
        currentlyAllowedLinebreaks = linebreaksAfter; 
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
            t = ClosingToken(tokenText, allowLineBreakBefore, postIndent, spaceBeforeDesire, spaceAfterDesire, context, charPositionInLine, alignSkip, preIndent);
            ret = null;
        } else {
            t = OpeningToken(tokenText, allowLineBreakBefore, postIndent, spaceBeforeDesire, spaceAfterDesire, charPositionInLine, alignSkip, preIndent);
            assert (is OpeningToken t); // ...yeah
            ret = t.context;
        }
        
        tokenQueue.add(t);
        
        isEmpty = false;
        writeLines();
        return ret;
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
        tokenQueue.add(EmptyClosing(context));
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
            variable Integer offset = options.indentMode.indent(
                tokenStack.fold(0, (Integer partial, FormattingContext elem) => partial + elem.postIndent)
            ).size;
            if (is Token firstToken = tokenQueue.find((QueueElement elem) => elem is Token), firstToken.preIndent != 0) {
                offset += firstToken.preIndent;
            }
            index = options.lineBreakStrategy.lineBreakLocation(
                tokenQueue.sequence,
                offset,
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
        QueueElement? lastElement = tokenQueue[i];
        "Tried to write too much into a line – not enough tokens!"
        assert(exists lastElement);
        
        if (is ClosingToken firstToken) {
            // this context needs to be closed *before* we write indentation
            // because closing it may reduce the indentation level
            closeContext0(firstToken);
        }
        FormattingContext? tmpIndent;
        if (is Token firstToken, firstToken.preIndent != 0) {
            object _tmpIndent satisfies FormattingContext { // TODO somehow avoid _tmpIndent
                postIndent = firstToken.preIndent;
            }
            tmpIndent = _tmpIndent;
            tokenStack.add(_tmpIndent);
        } else {
            tmpIndent = null;
        }
        
        writeIndentation();
        
        if (exists tmpIndent) {
            value deleted = tokenStack.deleteLast();
            assert(exists deleted, deleted == tmpIndent);
        }
        
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
                } else if (is Empty elem) {
                    handleContext(elem);
                }
                return null;
            };
        }
        while(tokenQueue.any(equalsOrSameText(lastElement))) {
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
            if (equalsOrSameText(removing)(tokenQueue.first)) {
                tokenQueue.deleteFirst();
            } else {
                // the element was already deleted somewhere in the elementHandler
            }
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
    
    [Integer?, {QueueElement|Stop*}] fastForwardComment(AntlrToken current, variable Integer? givenLineBreaks) {
        Range<Integer> before;
        Range<Integer> after;
        if (current.type == lineComment) {
            before = options.beforeLineCommentLineBreaks;
            after = options.afterLineCommentLineBreaks;
        } else {
            if (current.text.contains('\n') && !isEmpty) {
                before = options.beforeMultiCommentLineBreaks;
                after = options.afterMultiCommentLineBreaks;
            } else {
                before = options.beforeSingleCommentLineBreaks;
                after = options.afterSingleCommentLineBreaks;
            }
        }
        intersectAllowedLineBreaks(before, false);
        for (i in 0:lineBreakAmount(givenLineBreaks)) {
            tokenQueue.add(LineBreak());
        }
        currentlyAllowedLinebreaks = after;
        givenLineBreaks = givenLineBreaks exists then 0;
        // that’s it for the surrounding line breaks.
        // now we need to produce the following pattern: for each line in the comment,
        // line, line break, line, line break, ..., line.
        // notice how there’s no line break after the last line, which is why this gets
        // a little ugly...
        value lines = current.text
                .trim('\n'.equals) // line comments include the trailing line break
                .split('\n'.equals);
        String? firstLine = lines.first;
        assert (exists firstLine);
        SequenceAppender<QueueElement> ret = SequenceAppender<QueueElement> {
            OpeningToken(
                firstLine.trimTrailing('\r'.equals),
                true, 0, maxDesire - 1, maxDesire - 1)
        };
        ret.appendAll({
            for (line in lines
                    .rest
                    .map((String l) => l.trimTrailing('\r'.equals)))
                for (element in {LineBreak(), OpeningToken(line, true, 0, maxDesire, maxDesire)})
                    element
        });
        return [givenLineBreaks, ret.sequence];
    }
    
    "Enqueue a line break if the last queue element isn’t a line break, then flush the queue."
    shared void close() {
        if (!isEmpty) {
            writeToken {
                ""; // empty token, big effect: fastForward again, comments, newlines, etc.
                linebreaksBefore = 1..1;
                linebreaksAfter = 0..0;
                spaceBefore = false;
                spaceAfter = false;
            };
        }
    }
}
