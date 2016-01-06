import ceylon.test {
    assertEquals,
    test
}
import ceylon.formatter {
    FormattingWriter,
    maxDesire
}
import ceylon.formatter.options {
    parseLineBreakStrategy,
    FormattingOptions,
    LineBreakStrategy
}
import ceylon.file {
    Writer
}

class StringBuilderWriter(StringBuilder sb) satisfies Writer {
    void fail() { assert (false); }
    close() => noop();
    flush() => noop();
    write(String string) => sb.append(string);
    writeLine(String string) => fail();
    writeBytes({Byte*} bytes) => fail();
}

test
shared void testDefaultLineBreaksNearStart() {
    LineBreakStrategy? defaultLineBreaks = parseLineBreakStrategy("default");
    assert (exists defaultLineBreaks);
    StringBuilder sb = StringBuilder();
    FormattingWriter w = FormattingWriter(null, StringBuilderWriter(sb), FormattingOptions { lineBreakStrategy = defaultLineBreaks; maxLineLength = 20; });
    
    w.writeToken {
        "breakHere";
        lineBreaksBefore = 0..0;
        lineBreaksAfter = 0..1;
        indentBefore = 0;
        indentAfter = 0;
        spaceBefore = maxDesire;
        spaceAfter = maxDesire;
    };
    for (i in 1:10) {
        w.writeToken {
            "noBreakHere``i``";
            lineBreaksBefore = 0..(i==1 then 1 else 0);
            lineBreaksAfter = 0..1;
            indentBefore = 0;
            indentAfter = 0;
            spaceBefore = maxDesire;
            spaceAfter = maxDesire;
        };
    }
    w.destroy(null);
    assertEquals {
        expected = "breakHere
                    noBreakHere1 noBreakHere2 noBreakHere3 noBreakHere4 noBreakHere5 noBreakHere6 noBreakHere7 noBreakHere8 noBreakHere9 noBreakHere10
                    ";
        actual = sb.string;
    };
}

test
shared void testDefaultLineBreaksNoBreaks() {
    LineBreakStrategy? defaultLineBreaks = parseLineBreakStrategy("default");
    assert (exists defaultLineBreaks);
    StringBuilder sb = StringBuilder();
    FormattingWriter w = FormattingWriter(null, StringBuilderWriter(sb), FormattingOptions { lineBreakStrategy = defaultLineBreaks; maxLineLength = 20; });
    
    for (i in 1:10) {
        w.writeToken {
            "noBreakHere``i``";
            lineBreaksBefore = 0..0;
            lineBreaksAfter = 0..1;
            indentBefore = 0;
            indentAfter = 0;
            spaceBefore = maxDesire;
            spaceAfter = maxDesire;
        };
    }
    w.destroy(null);
    assertEquals {
        expected = "noBreakHere1 noBreakHere2 noBreakHere3 noBreakHere4 noBreakHere5 noBreakHere6 noBreakHere7 noBreakHere8 noBreakHere9 noBreakHere10
                    ";
        actual = sb.string;
    };
}

test
shared void testDefaultLineBreaksExplicitAtEnd() {
    LineBreakStrategy? defaultLineBreaks = parseLineBreakStrategy("default");
    assert (exists defaultLineBreaks);
    StringBuilder sb = StringBuilder();
    FormattingWriter w = FormattingWriter(null, StringBuilderWriter(sb), FormattingOptions { lineBreakStrategy = defaultLineBreaks; maxLineLength = 20; });
    
    for (i in 1:10) {
        w.writeToken {
            "noBreakHere``i``";
            lineBreaksBefore = 0..0;
            lineBreaksAfter = 0..1;
            indentBefore = 0;
            indentAfter = 0;
            spaceBefore = maxDesire;
            spaceAfter = maxDesire;
        };
    }
    w.requireAtLeastLineBreaks(1);
    w.destroy(null);
    assertEquals {
        expected = "noBreakHere1 noBreakHere2 noBreakHere3 noBreakHere4 noBreakHere5 noBreakHere6 noBreakHere7 noBreakHere8 noBreakHere9 noBreakHere10
                    ";
        actual = sb.string;
    };
}
