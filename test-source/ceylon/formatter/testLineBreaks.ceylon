import ceylon.test {
    test,
    assertEquals
}
import ceylon.formatter {
    FormattingWriter
}
import ceylon.formatter.options {
    FormattingOptions,
    LineBreak,
    lf,
    crlf,
    os
}
import ceylon.file {
    Writer
}
import ceylon.collection {
    StringBuilder
}

void testLineBreaks(LineBreak option, String lineBreak) {
    value sb = StringBuilder();
    object writer satisfies Writer {
        shared actual void close() => flush();
        
        shared actual void flush() {}
        
        shared actual void write(String string) {
            sb.append(string);
        }
        
        shared actual void writeLine(String line) {
            "FormattingWriter shouldn’t rely on Writer’s line break handling!"
            assert (false);
        }
        
        shared actual void writeBytes({Byte*} bytes) {
            throw AssertionError("Can’t write bytes");
        }
    }
    try (fWriter = FormattingWriter(null, writer, FormattingOptions {
            lineBreak = option;
        })) {
        fWriter.writeToken {
            "a";
            lineBreaksAfter = 2..2;
        };
        fWriter.writeToken {
            "b";
            lineBreaksBefore = 2..2;
        };
    }
    assertEquals(sb.string, "a``lineBreak.repeat(2)``b``lineBreak``");
}

test
shared void testLf()
        => testLineBreaks(lf, "\n");
test
shared void testCrlf()
        => testLineBreaks(crlf, "\r\n");
test
shared void testOs()
        => testLineBreaks(os, operatingSystem.newline);
