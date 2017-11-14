/********************************************************************************
 * Copyright (c) {date} Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import ceylon.file {
    Writer
}
import ceylon.collection {
    MutableList,
    LinkedList
}
import org.antlr.runtime {
    AntlrToken=Token,
    TokenStream
}
import org.eclipse.ceylon.compiler.typechecker.parser {
    CeylonLexer {
        lineComment=\iLINE_COMMENT,
        multiComment=\iMULTI_COMMENT,
        ws=\iWS,
        stringLiteral=\iSTRING_LITERAL,
        stringStart=\iSTRING_START,
        stringMid=\iSTRING_MID,
        stringEnd=\iSTRING_END,
        verbatimStringLiteral=\iVERBATIM_STRING
    }
}
import ceylon.formatter.options {
    FormattingOptions,
    Spaces,
    Tabs,
    Mixed
}

"The maximum value that is safe to use as [[FormattingWriter.writeToken]]’s `space[Before|After]` argument.
 
 Using a greater value risks inverting the intended result due to overflow."
shared Integer maxDesire = runtime.maxIntegerValue / 2;
"The minimum value that is safe to use as [[FormattingWriter.writeToken]]’s `space[Before|After]` argument.
 
 Using a smaller value risks inverting the intended result due to overflow."
shared Integer minDesire = runtime.minIntegerValue/2 + 1;

"Parses a `Boolean` or `Integer` value into a desire in range [[minDesire]]`..`[[maxDesire]].
 
 If [[desire]] is `Integer`, it is clamped to that range; if it’s `Boolean`, the returned
 value is [[minDesire]] for `false` and [[maxDesire]] for `true`."
shared Integer desire(Boolean|Integer desire) {
    if (is Integer desire) {
        return max { minDesire, min { maxDesire, desire } };
    } else {
        if (desire) {
            return maxDesire;
        } else {
            return minDesire;
        }
    }
}

shared Range<Integer> noLineBreak = 0..0;

"Used in [[FormattingWriter.fastForward]]."
abstract class Stop() of stopAndConsume | stopAndDontConsume {
    shared formal Boolean consume;
}
"Stop fast-forwarding and [[consume|org.antlr.runtime::IntStream.consume]] the current token."
see (`value stopAndDontConsume`)
object stopAndConsume extends Stop() {
    consume = true;
}
"Stop fast-forwarding and *don’t* consume the current token."
see (`value stopAndConsume`)
object stopAndDontConsume extends Stop() {
    consume = false;
}

see (`value AllowedLineBreaks.source`)
abstract class AllowedLineBreaksSource(shared actual String string)
        of token | comment | requireAtLeast | requireAtMost {}
object token extends AllowedLineBreaksSource("token") {}
object comment extends AllowedLineBreaksSource("comment") {}
object requireAtLeast extends AllowedLineBreaksSource("requireAtLeast") {}
object requireAtMost extends AllowedLineBreaksSource("requireAtMost") {}

class AllowedLineBreaks(range, source) {
    "The range of allowed line breaks."
    shared Range<Integer> range;
    "The source of this range of allowed line breaks.
     
     If the intersection with another range is empty,
     that’s okay as long as at least one of the ranges
     comes from a [[comment]]; then we choose that range."
    shared AllowedLineBreaksSource source;
    
    string => "``range``, from ``source``";
}

"A condition that dictates when a token’s indentation stacks."
shared abstract class StackCondition() of never | ifApplied | always {}
"Indicates that an indentation should never be stacked."
shared object never extends StackCondition() {
    string => "never";
}
"Indicates that an indentation should always be stacked."
shared object always extends StackCondition() {
    string => "always";
}
"Indicates that an indentation should be stacked if and only if it was applied, that is:
 - for the indentation before a token: if that token is the first of its line;
 - for the indentation after a token: if that token is the last of its line."
shared object ifApplied extends StackCondition() {
    string => "ifApplied";
}

"Writes tokens to an underlying [[writer]], respecting certain formatting settings and a maximum line width.
 
 The [[FormattingWriter]] manages the following aspects:
 
 * Indentation
 * Line Breaking
 * Spacing
 
 Additionally, it also writes comments if a [[token stream|tokens]] is given.
 
 # Indentation
 
 Two indentation levels are associated with each token: one before the token, and one after it.
 Each token also introduces a *context* which tracks these indentation levels if they *stack*.
 In this case, their indentation is applied to all subsequent lines until the context is *closed*.
 
 By default, the indentation before the token [[never]] stacks,
 and the indentation after the token [[always]] does.
 However, either indentation may also stack in the other case,
 or [[only if it is actually applied|ifApplied]], that is,
 only if that token is the first/last of its line.
 
 When the token is written, its context (instance of [[FormattingContext]])
 is pushed onto a *context stack*.
 The indentation of each line is then the sum of all indentation currently on the stack,
 plus the indentation before the current token and after the last token (if they’re not already on the stack).
 When a context is closed, the context and all contexts on top of it are removed from the context stack.
 
 A context can be closed in two ways:
 1. By associating it with a token.
    For example, you would say that a closing brace `}` closes the context of the corresponding opening brace `{`:
    The block has ended, and subsequent lines should no longer be indented as if they were still part of the block.
    Tokens that close another token’s context may not introduce indentation themselves,
    since they don’t get a context of their own.
 2. By calling [[closeContext]].
 
 You can also obtain a context not associated with any token by calling [[openContext]],
 which introduces some undirectional indentation that always stacks.
 This is mostly useful if you have a closing token with no designated opening token:
 for example, a statement’s closing semicolon `;` should close some context,
 but there is no corresponding token which opens that context.
 
 Examples:
 
 - An opening brace `{` has an `indentAfter` of 1, which always stacks.
   The resulting context is closed by the associated closing brace `}`.
 - A member operator `.` has an `indentBefore` of 1, which never stacks.
   If it stacked, you would get this:
   ~~~
   value someValue = something
       .foo(thing)
           .bar(otherThing)
               .baz(whyIsThisSoIndented);
   ~~~
 - A refinement operator `=>` has an `indentBefore` of 2, which stacks only if it is applied.
   Thus, you get both of the following results:
   ~~~
   Integer i => function(
       longArgument // only indented by one level, from the (
   );
   Integer f(String param1, String param2)
           => let (thing = param1.length, thing2 = param2.uppercased)
               thing + thing2.string; // indented from both => and let
   ~~~
 
 # Line Breaking
 
 Two [[Integer]] [[ranges|Range]] are associated with each token. One indicates how many line breaks
 may occur before the token, and the other indicates how many may occur after the token. Additionally,
 one may call [[requireAtLeastLineBreaks]] to further restrict how many line breaks may occur between
 two tokens.
 
 The intersection of these ranges for the border between two tokens is then used to determine how
 many line breaks should be written before the token.
 
 * If [[tokens]] exists, then each time a token is written, the token stream is fast-forwarded until
   the token is met (if a token with a different text is met, an exception is thrown). In
   fast-forwarding, the amount of line breaks is counted. After fast-forwarding has finished, the
   number of line breaks that were counted is clamped into the line break range, and this many
   line breaks are written.
 * If [[tokens]] doesn’t exist, then the first element of the range is used (usually the lowest,
   unless the range is [[decreasing|Range.decreasing]]).
 
 (Internally, the [[FormattingWriter]] also keeps track if a line break range came from [[writeToken]],
 [[requireAtLeastLineBreaks]], or was added internally when dealing with comments; an empty
 intersection of two ranges is usually a bug, unless one of the ranges comes from a comment,
 in which case we just use that range instead.)
 
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
 * `lineBreaksBefore, lineBreaksAfter` as determined by the [[options]]
     * [[lineBreaksBeforeLineComment|FormattingOptions.lineBreaksBeforeLineComment]] and
       [[lineBreaksAfterLineComment|FormattingOptions.lineBreaksAfterLineComment]] for `// line comments`
     * [[lineBreaksBeforeSingleComment|FormattingOptions.lineBreaksBeforeSingleComment]] and
       [[lineBreaksAfterSingleComment|FormattingOptions.lineBreaksAfterSingleComment]] for `/* single-line multi comments */`
     * [[lineBreaksBeforeMultiComment|FormattingOptions.lineBreaksBeforeMultiComment]] and
       [[lineBreaksAfterMultiComment|FormattingOptions.lineBreaksAfterMultiComment]] for
       ~~~
       /*
          multi-line
          comments
        */
       ~~~"
shared class FormattingWriter(shared TokenStream? tokens, Writer writer, FormattingOptions options)
        satisfies Destroyable {
    
    Integer tabWidth => 4; // TODO see ceylon/ceylon-spec#866
    "Keeps track of the length of the line that is currently being written.
     
     The width of a tab character is [[tabWidth]]."
    object countingWriter satisfies Writer {
        
        see (`value currentWidth`)
        variable Integer width = 0;
        "[[true]] if we’re at the start of the line and haven’t written anything other than indentation yet."
        variable Boolean startOfLine = true;
        "The current width of the line."
        shared Integer currentWidth => width;
        
        shared actual void close() => writer.close();
        
        shared actual void flush() => writer.flush();
        
        "Writes [[level]] levels of indentation,
         unless we’re not at the start of the line."
        shared void indent(Integer level) {
            if (startOfLine) {
                write(options.indentMode.indent(level));
                startOfLine = true;
            }
        }
        
        shared actual void write(String string) {
            startOfLine = false;
            String[] lines = string.lines.sequence();
            writer.write(lines.first else "");
            for (line in lines.rest) {
                writer.writeLine();
                width = 0;
                writer.write(line);
            }
            if (string.endsWith("\n")) {
                writer.writeLine();
                width = 0;
                startOfLine = true;
            } else {
                for (char in (lines.last else "")) {
                    if (char == '\t') {
                        width = (width%tabWidth == 0)
                                then width + tabWidth
                                else ((width / tabWidth) + 1) * tabWidth;
                    } else {
                        width += 1;
                    }
                }
            }
        }
        
        shared actual void writeLine(String line) {
            writer.write(line);
            writer.write(options.lineBreak.text);
            width = 0;
            startOfLine = true;
        }
        
        shared actual void writeBytes({Byte*} bytes) {
            throw AssertionError("Can’t write bytes");
        }
    }
    
    shared interface FormattingContext {
        shared formal Integer indent;
    }
    
    shared interface Element of OpeningElement | ClosingElement {
        shared formal FormattingContext context;
    }
    shared interface OpeningElement satisfies Element {}
    shared interface ClosingElement satisfies Element {}
    
    shared abstract class Empty() of EmptyOpening | EmptyClosing {}
    class EmptyOpening(Integer indent = 0) extends Empty() satisfies OpeningElement {
        shared actual object context satisfies FormattingContext {
            indent = outer.indent;
        }
    }
    class EmptyClosing(context) extends Empty() satisfies ClosingElement {
        shared actual FormattingContext context;
    }
    
    shared abstract class Token() of OpeningToken | ClosingToken | InvariantToken {
        
        shared formal String text;
        shared formal Boolean allowLineBreakBefore;
        shared formal Boolean allowLineBreakAfter;
        shared formal Integer indentBefore;
        shared formal Integer indentAfter;
        shared formal StackCondition stackIndentBefore;
        shared formal StackCondition stackIndentAfter;
        shared formal Integer wantsSpaceBefore;
        shared formal Integer wantsSpaceAfter;
        """The column to which subsequent lines of a multi-line token are aligned in the source.
           
           Consider the string literal in the following example:
           ~~~
           print(
             "Hello,
                World!");
           ~~~
           Here, the source column is 3, because the content of the string starts at column three,
           and the second line is aligned to that column.
           Formatted, the code looks like this:
           ~~~
           print(
               "Hello,
                  World!");
           ~~~
           The [[targetColumn]] of the string literal is 5 (because of the corrected indentation),
           therefore the second line should be aligned to that column.
           When the second line is then written, 3 spaces are first trimmed from it, arriving at
           `␣␣World!"`, which is the real content.
           Then, 5 spaces are added, so that `␣␣␣␣␣␣␣World!` is actually written.
           
           Usually, this is [[AntlrToken.charPositionInLine]] plus some constant value depending on the token type,
           like 1 for string literals and 3 for verbatim string literals.
           However, for string templates, things get more complicated:
           Later parts of the template are still aligned to the first part."""
        see (`value targetColumn`)
        see (`value AntlrToken.charPositionInLine`)
        shared formal Integer sourceColumn;
        """The column to which subsequent lines of a multi-line token should be aligned in the target.
           For an explanation of `source`- and `targetColumn`, see the [[sourceColumn]] documentation.
           
           (This needs to be lazily evaluated because it depends on [[countingWriter.currentWidth]]]."""
        see (`value sourceColumn`)
        shared formal Integer() targetColumn;
        
        shared actual String string => text;
    }
    shared class OpeningToken(text, allowLineBreakBefore, allowLineBreakAfter, indentBefore, indentAfter, stackIndentBefore, stackIndentAfter, wantsSpaceBefore, wantsSpaceAfter, sourceColumn, targetColumn)
            extends Token()
            satisfies OpeningElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Boolean allowLineBreakAfter;
        shared actual Integer indentBefore;
        shared actual Integer indentAfter;
        shared actual StackCondition stackIndentBefore;
        shared actual StackCondition stackIndentAfter;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual Integer sourceColumn;
        shared actual Integer() targetColumn;
        
        "The context of this token.
         Because the indentation ([[indentBefore]], [[indentAfter]])
         stacks depending on conditions ([[stackIndentBefore]], [[stackIndentAfter]]),
         the context’s [[indent]] isn’t known in advance;
         rather, the context must be initialized to specify
         if it’s the [[first|initBefore]] and/or [[last|initAfter]] token of its line,
         from which the [[indent]] can then be determined.."
        shared actual object context satisfies FormattingContext {
            variable Integer initedIndentBefore = -1;
            variable Integer initedIndentAfter = -1;
            shared actual Integer indent {
                assert (initedIndentBefore >= 0, initedIndentAfter >= 0);
                return initedIndentBefore + initedIndentAfter;
            }
            "Initialize the indentation before this token,
             based on whether this is the first token of its line or not.
             Calling this method multiple times has no effect;
             the first initialization is kept."
            shared void initBefore(Boolean firstOfLine) {
                if (initedIndentBefore == -1) {
                    if (stackIndentBefore==always ||
                                stackIndentBefore==ifApplied && firstOfLine) {
                        initedIndentBefore = indentBefore;
                    } else {
                        initedIndentBefore = 0;
                    }
                }
            }
            "Initialize the indentation after this token,
             based on whether this is the last token of its line or not.
             Calling this method multiple times overrides previous calls;
             the last initialization is used."
            shared void initAfter(Boolean lastOfLine) {
                if (stackIndentAfter==always ||
                            stackIndentAfter==ifApplied && lastOfLine) {
                    initedIndentAfter = indentAfter;
                } else {
                    initedIndentAfter = 0;
                }
            }
        }
    }
    shared class ClosingToken(text, allowLineBreakBefore, allowLineBreakAfter, wantsSpaceBefore, wantsSpaceAfter, context, sourceColumn, targetColumn)
            extends Token()
            satisfies ClosingElement {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Boolean allowLineBreakAfter;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual FormattingContext context;
        shared actual Integer sourceColumn;
        shared actual Integer() targetColumn;
        
        // disable indentation for closing tokens
        shared actual Integer indentBefore => 0;
        shared actual Integer indentAfter => 0;
        shared actual StackCondition stackIndentBefore => never;
        shared actual StackCondition stackIndentAfter => never;
    }
    shared class InvariantToken(text, allowLineBreakBefore, allowLineBreakAfter, wantsSpaceBefore, wantsSpaceAfter, sourceColumn, targetColumn)
            extends Token() {
        
        shared actual String text;
        shared actual Boolean allowLineBreakBefore;
        shared actual Boolean allowLineBreakAfter;
        shared actual Integer wantsSpaceBefore;
        shared actual Integer wantsSpaceAfter;
        shared actual Integer sourceColumn;
        shared actual Integer() targetColumn;
        
        // disable indentation for invariant tokens
        shared actual Integer indentBefore => 0;
        shared actual Integer indentAfter => 0;
        shared actual StackCondition stackIndentBefore => never;
        shared actual StackCondition stackIndentAfter => never;
    }
    
    shared class LineBreak() {}
    
    shared alias QueueElement => Token|Empty|LineBreak;
    
    "The `tokenQueue` holds all tokens that have not yet been written."
    variable MutableList<QueueElement> tokenQueue = LinkedList<QueueElement>();
    "The `tokenStack` holds all tokens that have been written, but whose context has not yet been closed."
    MutableList<FormattingContext> tokenStack = LinkedList<FormattingContext>();
    
    "Remembers if anything was ever enqueued."
    variable Boolean isEmpty = true;
    
    "Must not allow no line breaks after a line comment, breaks syntax"
    assert (min(options.lineBreaksAfterLineComment) > 0);
    
    class ColumnStackEntry(sourceColumn) {
        shared Integer sourceColumn;
        shared variable Integer targetColumn = 0;
    }
    
    "A stack to keep track of [[source|Token.sourceColumn]]- and [[targetColumn|Token.targetColumn]]s.
     
     See also issue [#39](https://github.com/lucaswerkmeister/ceylon.formatter/issues/39)."
    MutableList<ColumnStackEntry> columnStack = LinkedList<ColumnStackEntry>();
    
    """For multi-line tokens like
       ~~~
       "foo
        bar ``1`` baz"
       ~~~
       The `wantsSpaceAfter` is lost because by the time the `1` is written, the multi-line token
       is already vanished from the [[tokenQueue]], and only its context remains in the [[tokenStack]].
       To remedy that, we have to remember that information in this variable.
       
       See also [#41](https://github.com/lucaswerkmeister/ceylon.formatter/issues/41)."""
    variable Integer? multiLineWantsSpaceAfter = null;
    
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
    
    "Indentation that does not stack, but needs to be persisted between two lines:
     The indentation after a token that becomes the last of its line, if it doesn’t stack,
     isn’t stored on the indentation stack,
     but still needs to be persisted until the next line is written,
     and is for that purpose stored in this variable."
    variable Integer ephemeralIndentation = 0;
    
    variable AllowedLineBreaks currentlyAllowedLinebreaks = AllowedLineBreaks(0..0, requireAtLeast);
    
    variable Integer? givenLineBreaks = tokens exists then 0;
    
    "Intersect the range of allowed line breaks between the latest token and the next one to be [[written|writeToken]]
     with the given range."
    see (`function requireAtLeastLineBreaks`)
    void intersectAllowedLineBreaks(
        AllowedLineBreaks other,
        "If [[true]], [[FormattingWriter.fastForward]] the token stream before intersecting the line breaks.
         This makes a difference if there are comments between the latest and the next token; with fast-forwarding,
         the intersection will be applied between the comments and the next token, while without it, the intersection
         will be applied between the latest token and the comments."
        Boolean fastForwardFirst = true) {
        if (fastForwardFirst) {
            fastForward((AntlrToken? current) {
                    if (exists current) {
                        assert (exists lineBreaks = givenLineBreaks);
                        if (current.type==lineComment || current.type==multiComment) {
                            return fastForwardComment(current);
                        } else if (current.type == ws) {
                            givenLineBreaks = lineBreaks + current.text.count('\n'.equals);
                            return empty;
                        } else {
                            return { stopAndDontConsume }; // end fast-forwarding
                        }
                    } else {
                        return { stopAndDontConsume }; // end fast-forwarding
                    }
                });
        }
        Range<Integer> currentRange = currentlyAllowedLinebreaks.range;
        Range<Integer> otherRange = other.range;
        value inc1 = currentRange.decreasing then currentRange.reversed else currentRange;
        value inc2 = otherRange.decreasing then otherRange.reversed else otherRange;
        variable value intersect = max { inc1.first, inc2.first } .. min { inc1.last, inc2.last };
        if (intersect.decreasing) {
            /*
             The intersection was empty!
             If one or both of the ranges came from a comment,
             this is somewhat expected (because comments can
             appear everywhere, and there are options to configure
             their ranges), and we resolve the conflict by using
             just the comment’s range.
             Otherwise, it’s probably a bug.
             */
            if (currentlyAllowedLinebreaks.source==comment && other.source==comment) {
                // use the union instead
                intersect = min { inc1.first, inc2.first } .. max { inc1.last, inc2.last };
            } else if (currentlyAllowedLinebreaks.source == comment) {
                intersect = currentRange;
            } else if (other.source == comment) {
                intersect = otherRange;
            }
        }
        assert (!intersect.decreasing);
        currentlyAllowedLinebreaks
                = AllowedLineBreaks {
                    range = currentRange.decreasing then intersect.last..intersect.first else intersect;
                    value source {
                        if (other.source==requireAtLeast || other.source==requireAtMost) {
                            return currentlyAllowedLinebreaks.source;
                        } else {
                            return other.source;
                        }
                    }
                };
    }
    
    "Require at least [[limit]] line breaks between the latest token and the next one to be [[written|writeToken]]."
    shared void requireAtLeastLineBreaks(
        Integer limit,
        "If [[true]], [[FormattingWriter.fastForward]] the token stream before intersecting the line breaks.
         This makes a difference if there are comments between the latest and the next token; with fast-forwarding,
         the intersection will be applied between the comments and the next token, while without it, the intersection
         will be applied between the latest token and the comments."
        Boolean fastForwardFirst = true)
            => intersectAllowedLineBreaks(AllowedLineBreaks(limit..runtime.maxIntegerValue, requireAtLeast), fastForwardFirst);
    
    "Require at most [[limit]] line breaks between the latest token and the next one to be [[written|writeToken]]."
    shared void requireAtMostLineBreaks(
        Integer limit,
        "If [[true]], [[FormattingWriter.fastForward]] the token stream before intersecting the line breaks.
         This makes a difference if there are comments between the latest and the next token; with fast-forwarding,
         the intersection will be applied between the comments and the next token, while without it, the intersection
         will be applied between the latest token and the comments."
        Boolean fastForwardFirst = true)
            => intersectAllowedLineBreaks(AllowedLineBreaks(runtime.minIntegerValue..limit, requireAtMost), fastForwardFirst);
    
    "Based on [[currently allowed line breaks|currentlyAllowedLinebreaks]]
     and the [[given amount of line breaks|givenLineBreaks]],
     decide how many line breaks should be printed.
     
     The current implementation will clamp the given line breaks into the allowed range
     or use the first value of the allowed range if they’re null."
    Integer lineBreakAmount(Integer? givenLineBreaks) {
        if (is Integer givenLineBreaks) {
            return min { max { givenLineBreaks, min(currentlyAllowedLinebreaks.range) }, max(currentlyAllowedLinebreaks.range) };
        } else {
            return currentlyAllowedLinebreaks.range.first;
        }
    }
    
    "Add a single token, then try to write out a line.
     
     See the [[class documentation|FormattingWriter]] for more information on the token model
     and how the various parameters of a token interact.
     
     All parameters (except [[token]], of course) default to a “save to ignore” / “don’t care” value."
    shared FormattingContext? writeToken(
        token,
        context = null,
        indentBefore = 0,
        indentAfter = 0,
        stackIndentBefore = never,
        stackIndentAfter = always,
        lineBreaksBefore = 0..2,
        lineBreaksAfter = 0..1,
        spaceBefore = 0,
        spaceAfter = 0,
        tokenInStream = token) {
        
        // parameters
        "The token."
        AntlrToken|String token;
        "The context that this token closes. If this value isn’t `null`, then this token will not
         itself open a new context, and the method will therefore return `null`."
        FormattingContext? context;
        "The indentation before this token."
        Integer indentBefore;
        "The indentation after this token."
        Integer indentAfter;
        "The condition under which to stack the indentation before this token.
         By default, the indentation before a token [[never]] stacks."
        StackCondition stackIndentBefore;
        "The condition under which to stack the indentation after this token.
         By default, the indentation after a token [[always]] stacks."
        StackCondition stackIndentAfter;
        "The amount of line breaks that is allowed before this token."
        see (`value noLineBreak`)
        Range<Integer> lineBreaksBefore;
        "The amount of line breaks that is allowed after this token."
        Range<Integer> lineBreaksAfter;
        "Whether to put a space before this token.
         
         [[true]] and [[false]] are sugar for [[maxDesire]] and [[minDesire]], respectively."
        see (`value maxDesire`, `value minDesire`)
        Integer|Boolean spaceBefore;
        "Whether to put a space after this token.
         
         [[true]] and [[false]] are sugar for [[maxDesire]] and [[minDesire]], respectively."
        see (`value maxDesire`, `value minDesire`)
        Integer|Boolean spaceAfter;
        "The token that is expected to occur in the token stream for this token.
         
         In virtually all cases, this is the same as [[token]]; however, for identifiers, the
         `\\i`/`\\I` that is sometimes part of the code isn’t included in the token text, so
         in this case you would pass, for example, `\\ivalue` as [[token]] and `value` as
         [[tokenInStream]],"
        AntlrToken|String tokenInStream;
        
        "Line break count range must be nonnegative"
        assert (lineBreaksBefore.first>=0 && lineBreaksBefore.last>=0);
        "Line break count range must be nonnegative"
        assert (lineBreaksAfter.first>=0 && lineBreaksAfter.last>=0);
        
        // desugar
        Integer spaceBeforeDesire;
        Integer spaceAfterDesire;
        String tokenText;
        String tokenInStreamText;
        Boolean allowLineBreakBefore;
        Boolean allowLineBreakAfter;
        spaceBeforeDesire = desire(spaceBefore);
        spaceAfterDesire = desire(spaceAfter);
        if (is AntlrToken token) {
            tokenText = token.text;
        } else {
            tokenText = token;
        }
        if (is AntlrToken tokenInStream) {
            tokenInStreamText = tokenInStream.text;
        } else {
            tokenInStreamText = tokenInStream;
        }
        allowLineBreakBefore = lineBreaksBefore.any(0.smallerThan);
        allowLineBreakAfter = lineBreaksAfter.any(0.smallerThan);
        
        /*
         handle the part before this token:
         fast-forward, intersect allowed line breaks, write out line breaks
         */
        fastForward((AntlrToken? current) {
                if (exists current) {
                    assert (exists lineBreaks = givenLineBreaks);
                    if (current.type==lineComment || current.type==multiComment) {
                        /*
                         we treat comments as regular tokens
                         just with the difference that their before- and afterToken range isn’t given, but an option instead
                         */
                        return fastForwardComment(current);
                    } else if (current.type == ws) {
                        givenLineBreaks = lineBreaks + current.text.count('\n'.equals);
                        return empty;
                    } else if (current.type == -1) {
                        // EOF
                        return { stopAndDontConsume };
                    } else if (current.text == tokenInStreamText) {
                        return { stopAndConsume }; // end fast-forwarding
                    } else {
                        String expected;
                        if (is AntlrToken token) {
                            expected = " (``token.string``)";
                        } else {
                            expected = "";
                        }
                        value ex = Exception("Unexpected token '``current.text``' (``current``), expected '``tokenText``'``expected`` instead");
                        if (options.failFast) {
                            throw ex;
                        } else {
                            ex.printStackTrace();
                            // attempt to recover by just writing out tokens until we find the right one
                            return { OpeningToken {
                                    current.text;
                                    allowLineBreakBefore = true;
                                    allowLineBreakAfter = true;
                                    indentBefore = 0;
                                    indentAfter = 0;
                                    stackIndentBefore = never;
                                    stackIndentAfter = never;
                                    wantsSpaceBefore = 0;
                                    wantsSpaceAfter = 0;
                                    sourceColumn = 0;
                                    targetColumn = () => countingWriter.currentWidth;
                                } };
                        }
                    }
                } else {
                    return { stopAndDontConsume }; // end fast-forwarding
                }
            });
        intersectAllowedLineBreaks(AllowedLineBreaks(lineBreaksBefore, package.token), false);
        for (i in 0 : lineBreakAmount(givenLineBreaks)) {
            tokenQueue.add(LineBreak());
        }
        givenLineBreaks = tokens exists then 0;
        /*
         handle this token:
         set allowed line breaks, add token
         */
        currentlyAllowedLinebreaks = AllowedLineBreaks(lineBreaksAfter, package.token);
        FormattingContext? ret;
        Token t;
        see (`value Token.sourceColumn`)
        Integer sourceColumn;
        see (`value Token.targetColumn`)
        Integer() targetColumn;
        switch (token)
        case (is AntlrToken) {
            if (token.type == stringStart) {
                /*
                 start of a string template:
                 save this token’s source and target column,
                 as the other parts are aligned to the same columns (not their own).
                 */
                sourceColumn = token.charPositionInLine + 1;
                variable value entry = ColumnStackEntry(sourceColumn);
                columnStack.add(entry);
                targetColumn = () {
                    value target = countingWriter.currentWidth + 1;
                    entry.targetColumn = target;
                    return target;
                };
            } else if (token.type == stringMid) {
                /*
                 middle part of a string template:
                 reuse start’s source and target column
                 */
                assert (exists entry = columnStack.last);
                sourceColumn = entry.sourceColumn;
                targetColumn = () => entry.targetColumn;
            } else if (token.type == stringEnd) {
                /*
                 end of a string template:
                 reuse start’s source and target column,
                 then remove them from the stack
                 */
                assert (exists entry = columnStack.deleteLast());
                sourceColumn = entry.sourceColumn;
                targetColumn = () => entry.targetColumn;
            } else if (token.type == stringLiteral) {
                sourceColumn = token.charPositionInLine + 1;
                targetColumn = () => countingWriter.currentWidth + 1;
            } else if (token.type == verbatimStringLiteral) {
                sourceColumn = token.charPositionInLine + 3;
                targetColumn = () => countingWriter.currentWidth + 3;
            } else {
                sourceColumn = token.charPositionInLine;
                targetColumn = () => countingWriter.currentWidth;
            }
        }
        case (is String) {
            sourceColumn = 0; // meaningless
            /*
             hack: for now we assume the only multi-line tokens are multi-line string literals,
             so we use the amount of leading quotes to know how much we have to skip
             */
            targetColumn = () => countingWriter.currentWidth + token.takeWhile('"'.equals).size;
        }
        if (exists context) {
            "Token that closes context cannot open its own context and therefore must not introduce indentation"
            assert (indentBefore==0 && indentAfter==0);
            // Note: We *could* allow indentation that doesn’t stack. Does anyone need that?
            // (Alternatively, we could allow closing and opening a context simultaneously, but that’s a more major change.)
            
            t = ClosingToken(tokenText, allowLineBreakBefore, allowLineBreakAfter, spaceBeforeDesire, spaceAfterDesire, context, sourceColumn, targetColumn);
            ret = null;
        } else {
            t = OpeningToken(tokenText, allowLineBreakBefore, allowLineBreakAfter, indentBefore, indentAfter, stackIndentBefore, stackIndentAfter, spaceBeforeDesire, spaceAfterDesire, sourceColumn, targetColumn);
            assert (is OpeningToken t); // ...yeah
            ret = t.context;
        }
        
        tokenQueue.add(t);
        
        isEmpty = false;
        writeLines();
        return ret;
    }
    
    "Open a [[FormattingContext]] not associated with any token."
    shared FormattingContext openContext(Integer indentAfter = 0) {
        value noToken = EmptyOpening(indentAfter);
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
         2. If it’s a (subclass of) [[Token]], replace it with an [[InvariantToken]].
     * If the associated context isn’t on the queue:
         1. Pop the context and its successors from the [[tokenStack]]
         2. Go through the `tokenQueue` from the beginning until `element` and do the same as above."
    void closeContext0(ClosingElement&QueueElement element) {
        Integer? startIndex = tokenQueue.firstIndexWhere((QueueElement e) {
                if (is OpeningElement e, e.context == element.context) {
                    return true;
                }
                return false;
            });
        Integer? endIndex = tokenQueue.firstIndexWhere(element.equals);
        
        if (exists endIndex) {
            if (exists startIndex) {
                // first case: only affects token queue
                filterQueue(startIndex, endIndex);
            } else {
                // second case: affects token stack and queue
                Integer? stackIndex = tokenStack.firstIndexWhere(element.context.equals);
                if (exists stackIndex) {
                    for (i in stackIndex .. tokenStack.size-1) {
                        tokenStack.deleteLast();
                    }
                }
                filterQueue(0, endIndex);
            }
        } else {
            // third case: only affects token stack
            assert (is Null startIndex);
            Integer? stackIndex = tokenStack.firstIndexWhere(element.context.equals);
            if (exists stackIndex) {
                for (i in stackIndex .. tokenStack.size-1) {
                    tokenStack.deleteLast();
                }
            }
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
                            return InvariantToken(elem.text, elem.allowLineBreakBefore, elem.allowLineBreakAfter, elem.wantsSpaceBefore, elem.wantsSpaceAfter, elem.sourceColumn, elem.targetColumn);
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
        Boolean addLineBreak;
        if (is Integer length = options.maxLineLength) {
            Integer offset;
            if (countingWriter.currentWidth > 0) {
                // part of a multi-line token is already in the current line;
                // signal this to the line break strategy by passing a positive argument
                offset = countingWriter.currentWidth;
            } else {
                // the offset is just indentation: stacked indents plus potential indentBefore plus ephemeral indent;
                // signal this to the line break strategy by passing a negative argument
                variable Integer o = options.indentMode.indent(
                    tokenStack.fold(0, (partial, elem) => partial + elem.indent)
                ).size;
                if (is Token firstToken = tokenQueue.find((QueueElement elem) => elem is Token)) {
                    o += firstToken.indentBefore;
                }
                o += ephemeralIndentation;
                offset = -o;
            }
            let ([i, lb] = options.lineBreakStrategy.lineBreakLocation(
                    tokenQueue.sequence(),
                    offset,
                    length));
            index = i;
            addLineBreak = lb;
        } else {
            index = tokenQueue.firstIndexWhere(function(QueueElement element) {
                    if (is LineBreak element) {
                        return true;
                    } else if (is Token element, element.text.contains('\n')) {
                        return true;
                    }
                    return false;
                });
            addLineBreak = false;
        }
        if (exists index) {
            if (addLineBreak) {
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
        while (tryNextLine()) {}
    }
    
    "Write `i + 1` tokens from the queue, followed by a line break.
     
     1. Take elements `0..i` from the queue
        (making the formerly `i + 1`<sup>th</sup> token the new first token).
     2. Determine the first token in that range.
     3. If the first token is a [[ClosingToken]], [[close|closeContext]] its context.
        This way, a token that closes a context (e. g. a closing brace)
        gets the same indentation situation as the token that opened it (the opening brace),
        aligning with that instead of the content between the two tokens.
     4. [[Write indentation|writeIndentation]].
     5. Write the elements:
         * If the last token contains more than one line: [[write]] all tokens directy,
           then [[handle|handleContext]] their contexts afterwards;
         * otherwise write only the first token directly, since its context was already
           closed in `3.`, and write the others [[with context|writeWithContext]].
     6. If the last element isn’t multi-line: write a line break.
     
     (Note that there may not appear any line breaks before token `i`.)
     
     (Note: I *think* the special case in step 5 is necessary
     because otherwise the lines from the multi-line token would be misaligned,
     since they wouldn’t be based on the indentation of the first line.
     However, I’m writing this note two years after the rest of this method,
     so this is just an educated guess after looking at the code;
     I don’t actually *remember* the reason.
     So if something needs to change here, don’t trust this note too much.)"
    void writeLine(Integer i) {
        QueueElement? firstToken = tokenQueue[0..i].find((QueueElement elem) => elem is Token);
        QueueElement? lastToken = tokenQueue[0..i].findLast((QueueElement elem) => elem is Token);
        QueueElement? lastElement = tokenQueue[i];
        "Tried to write too much into a line – not enough tokens!"
        assert (exists lastElement);
        
        switch (firstToken)
        case (is ClosingToken) {
            /*
             This context needs to be closed *before* we write indentation
             because closing it may reduce the indentation level.
             */
            closeContext0(firstToken);
        }
        case (is OpeningToken) {
            // initialize context
            firstToken.context.initBefore { firstOfLine = true; };
            // we’ll also need to write the indentation before this token,
            // since it’s not on the context stack yet,
            // but that has to happen after writeIndentation() below,
            // otherwise writeIndentation() refuses to do anything
        }
        else {
            // no indentation, nothing to do
        }
        
        if (firstToken exists || options.indentBlankLines) {
            writeIndentation();
        }
        
        if (is OpeningToken firstToken) {
            // explicitly write indentation for just this line – context is pushed on stack below
            countingWriter.indent(firstToken.indentBefore);
        }
        
        countingWriter.indent(ephemeralIndentation);
        ephemeralIndentation = 0;
        
        variable Token? previousToken = null;
        "The elements we have to handle later in case we’re writing a multi-line token"
        value elementsToHandle = LinkedList<QueueElement>();
        "The function that handles elements. If the last token is a multi-line token,
         it [[writes|write]] tokens directly and adds the elements to [[elementsToHandle]].
         otherwise it writes tokens [[with context|writeWithContext]] and opens/closes
         [[EmptyOpenings|EmptyOpening]]/[[-Closings|EmptyClosing]]."
        Anything(QueueElement) elementHandler;
        if (is Token lastToken, lastToken.text.contains('\n')) {
            elementHandler = function(QueueElement elem) {
                if (is Token t = elem) {
                    write(t);
                }
                elementsToHandle.add(elem);
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
        while (tokenQueue.any(equalsOrSameText(lastElement))) {
            QueueElement? removing = tokenQueue.first;
            assert (exists removing);
            if (is Token currentToken = removing) {
                Integer? wantsSpaceAfter;
                if (exists p = previousToken) {
                    wantsSpaceAfter = p.wantsSpaceAfter;
                } else if (exists m = multiLineWantsSpaceAfter) {
                    wantsSpaceAfter = m;
                } else {
                    wantsSpaceAfter = null;
                }
                if (exists wantsSpaceAfter, wantsSpaceAfter+currentToken.wantsSpaceBefore >= 0) {
                    countingWriter.write(" ");
                }
                if (exists firstToken, currentToken == firstToken, is ClosingToken currentToken) {
                    // don’t attempt to close this context, we already did that
                    countingWriter.write(currentToken.text);
                } else {
                    elementHandler(currentToken);
                }
                previousToken = currentToken;
                if (is OpeningToken currentToken) {
                    // initialize context – we’re in the middle of the line
                    // (in the cases where that’s not true,
                    // the explicit earlier/later call wins, so it’s no problem)
                    currentToken.context.initBefore { firstOfLine = false; };
                    currentToken.context.initAfter { lastOfLine = false; };
                }
            } else if (is EmptyOpening|EmptyClosing removing) {
                elementHandler(removing);
            }
            if (equalsOrSameText(removing)(tokenQueue.first)) {
                tokenQueue.deleteFirst();
            } else {
                // the element was already deleted somewhere in the elementHandler
            }
            multiLineWantsSpaceAfter = null;
        }
        for (token in elementsToHandle.sequence()) {
            handleContext(token);
        }
        if (is OpeningToken lastToken) {
            // initialize context
            lastToken.context.initAfter { lastOfLine = true; };
            if (lastToken.stackIndentAfter == never) {
                // save indentation so that it’s written for just the next line
                ephemeralIndentation = lastToken.indentAfter;
            }
        }
        
        if (is Token lastElement, lastElement.text.contains('\n')) {
            // don’t write a line break
            // but store wantsSpaceAfter information
            multiLineWantsSpaceAfter = lastElement.wantsSpaceAfter;
        } else {
            countingWriter.writeLine();
        }
    }
    
    "Write indentation – the sum of all `indent`s on the [[tokenStack]]."
    void writeIndentation()
            => countingWriter.indent(tokenStack.fold(0, (partial, elem) => partial + elem.indent));
    
    "Write a token.
     
     1. [[write]] the token’s text
     2. [[handle|handleContext]] the token’s context"
    void writeWithContext(Token token) {
        write(token);
        handleContext(token);
    }
    
    "Write the token’s text. If it contains more than one line, pad the subsequent lines.
     
     The [[source|Token.sourceColumn]]- and [[target|Token.targetColumn]] column are taken
     from the token before writing the first line.
     The subsequent lines are [[trimmed|trimIndentation]], indented with the current indentation
     level (see [[tokenStack]]) using [[options]]`.`[[indentMode|FormattingOptions.indentMode]],
     then aligned to the column with spaces."
    void write(Token token) {
        "The column where the text was originally aligned to."
        Integer sourceColumn = token.sourceColumn;
        "The column where we want to align the text to."
        Integer targetColumn = token.targetColumn();
        String[] lines = token.text.split {
            splitting = '\n'.equals;
            groupSeparators = false; // keep empty lines
        }.collect((String s) => s.trimTrailing('\r'.equals));
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
    
    {QueueElement|Stop*} fastForwardComment(AntlrToken current) {
        Range<Integer> before;
        Range<Integer> after;
        if (current.type == lineComment) {
            before = options.lineBreaksBeforeLineComment;
            after = options.lineBreaksAfterLineComment;
        } else {
            if (current.text.contains('\n') && !isEmpty) {
                before = options.lineBreaksBeforeMultiComment;
                after = options.lineBreaksAfterMultiComment;
            } else {
                before = options.lineBreaksBeforeSingleComment;
                after = options.lineBreaksAfterSingleComment;
            }
        }
        intersectAllowedLineBreaks(AllowedLineBreaks(before, comment), false);
        MutableList<QueueElement> ret = LinkedList<QueueElement>();
        for (i in 0 : lineBreakAmount(givenLineBreaks else 1)) {
            ret.add(LineBreak());
        }
        currentlyAllowedLinebreaks = AllowedLineBreaks(after, comment);
        givenLineBreaks = current.type == lineComment then 1 else 0;
        
        value token = OpeningToken {
            text = current.text.trimTrailing('\n'.equals).trimTrailing('\r'.equals);
            allowLineBreakBefore = true;
            allowLineBreakAfter = true;
            indentBefore = 0;
            indentAfter = 0;
            stackIndentBefore = never;
            stackIndentAfter = never;
            wantsSpaceBefore = maxDesire - 1;
            wantsSpaceAfter = maxDesire - 1;
            sourceColumn =
                /*
                 TODO
                 this should just be current.charPositionInLine…
                 … but due to a bug in ANTLR we need a special case for the first token
                 */
                current.tokenIndex == 0
                /*
                 sometimes, the very first token has a charPositionInLine of != 0
                 I have no idea why or when this happens
                 */
                        then 0
                        else current.charPositionInLine;
            targetColumn = () => countingWriter.currentWidth;
        };
        ret.add(token);
        return ret.sequence();
    }
    
    "Enqueue a line break if the last queue element isn’t a line break, then flush the queue."
    shared actual void destroy(Throwable? error) {
        writeToken {
            ""; // empty token, big effect: fastForward again, comments, newlines, etc.
            lineBreaksBefore = isEmpty then 0..0 else 1..1;
            lineBreaksAfter = 0..0;
            spaceBefore = false;
            spaceAfter = false;
        };
    }
}
