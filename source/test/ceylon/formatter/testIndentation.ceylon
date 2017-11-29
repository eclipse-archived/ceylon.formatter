import ceylon.formatter {
    FormattingWriter,
    never,
    ifApplied,
    always
}
import ceylon.formatter.options {
    FormattingOptions
}
import ceylon.test {
    test,
    assertEquals
}

"Write a single token with the text `noIndent` and with no indentation to [[w]]."
void writeNoIndent(FormattingWriter w) {
    w.writeToken {
        "noIndent";
        indentBefore = 0;
        indentAfter = 0;
        lineBreaksBefore = 0..1;
        lineBreaksAfter = 1..0;
    };
}

"Test the [[FormattingWriter]].
 [[commands]] specifies a list of commands to call on `w`.
 Afterwards, the output of the writer is asserted to be equal to the [[expected]] output."
void testFormattingWriter(void commands(FormattingWriter w), String expected) {
    StringBuilder sb = StringBuilder();
    FormattingWriter w = FormattingWriter(null, StringBuilderWriter(sb), FormattingOptions());
    commands(w);
    w.destroy(null);
    assertEquals {
        expected = expected;
        actual = sb.string;
    };
}

test
shared void testIndentBeforeStackNever() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackNever";
                indentBefore = 1;
                stackIndentBefore = never;
                lineBreaksBefore = 1..1;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent
                        indentBeforeOneStackNever
                    noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackNever";
                indentBefore = 1;
                stackIndentBefore = never;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent indentBeforeOneStackNever
                    noIndent
                    ";
    };
}

test
shared void testIndentBeforeStackIfApplied() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackIfApplied";
                indentBefore = 1;
                stackIndentBefore = ifApplied;
                lineBreaksBefore = 1..1;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent
                        indentBeforeOneStackIfApplied
                        noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackIfApplied";
                indentBefore = 1;
                stackIndentBefore = ifApplied;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent indentBeforeOneStackIfApplied
                    noIndent
                    ";
    };
}

test
shared void testIndentBeforeStackAlways() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackAlways";
                indentBefore = 1;
                stackIndentBefore = always;
                lineBreaksBefore = 1..1;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent
                        indentBeforeOneStackAlways
                        noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            writeNoIndent(w);
            w.writeToken {
                "indentBeforeOneStackAlways";
                indentBefore = 1;
                stackIndentBefore = always;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
        }
        expected = "noIndent indentBeforeOneStackAlways
                        noIndent
                    ";
    };
}

test
shared void testIndentAfterStackNever() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackNever";
                indentAfter = 1;
                stackIndentAfter = never;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackNever
                        noIndent
                    noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackNever";
                indentAfter = 1;
                stackIndentAfter = never;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 0..0;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackNever noIndent
                    noIndent
                    ";
    };
}

test
shared void testIndentAfterStackIfApplied() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackIfApplied";
                indentAfter = 1;
                stackIndentAfter = ifApplied;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackIfApplied
                        noIndent
                        noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackIfApplied";
                indentAfter = 1;
                stackIndentAfter = ifApplied;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 0..0;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackIfApplied noIndent
                    noIndent
                    ";
    };
}

test
shared void testIndentAfterStackAlways() {
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackAlways";
                indentAfter = 1;
                stackIndentAfter = always;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 1..1;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackAlways
                        noIndent
                        noIndent
                    ";
    };
    testFormattingWriter {
        void commands(FormattingWriter w) {
            w.writeToken {
                "indentAfterOneStackAlways";
                indentAfter = 1;
                stackIndentAfter = always;
                lineBreaksBefore = 0..0;
                lineBreaksAfter = 0..0;
            };
            writeNoIndent(w);
            writeNoIndent(w);
        }
        expected = "indentAfterOneStackAlways noIndent
                        noIndent
                    ";
    };
}
