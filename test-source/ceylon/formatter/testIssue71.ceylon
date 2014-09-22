import ceylon.test {
    test,
    assertEquals,
    assertFalse
}
import ceylon.file {
    parsePath,
    File,
    Nil,
    Writer
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree
}
import org.antlr.runtime {
    ANTLRFileStream,
    BufferedTokenStream,
    CommonTokenStream
}
import com.redhat.ceylon.compiler.typechecker.parser {
    CeylonLexer,
    CeylonParser
}
import ceylon.formatter.options {
    crlf,
    lf,
    FormattingOptions
}

test
shared void testIssue71() {
    assert (is Nil n = parsePath("testIssue71.ceylon").resource);
    File f = n.createFile();
    try {
        try (w = f.Overwriter()) {
            w.write(
                "/*
                  a
                  comment
                  */
                 void testIssue71() {
                 }".replace("\n", "\r\n"));
        }
        value stream = ANTLRFileStream(f.path.string);
        CeylonLexer lexer = CeylonLexer(stream);
        Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        lexer.reset();
        StringBuilder b1 = StringBuilder();
        object w1 satisfies Writer {
            shared actual void close() {}
            shared actual void flush() {}
            shared actual void write(String string) {
                b1.append(string);
            }
            shared actual void writeLine(String line) { assert (false); }
            shared actual void writeBytes({Byte*} bytes) {
                throw AssertionError("Can’t write bytes");
            }
        }
        format(cu, FormattingOptions { lineBreak = lf; }, w1, BufferedTokenStream(lexer));
        assertFalse(b1.string.contains("\r\n"));
        lexer.reset();
        StringBuilder b2 = StringBuilder();
        object w2 satisfies Writer {
            shared actual void close() {}
            shared actual void flush() {}
            shared actual void write(String string) {
                b2.append(string);
            }
            shared actual void writeLine(String line) { assert (false); }
            shared actual void writeBytes({Byte*} bytes) {
                throw AssertionError("Can’t write bytes");
            }
        }
        format(cu, FormattingOptions { lineBreak = crlf; }, w2, BufferedTokenStream(lexer));
        value string = b2.string;
        assertFalse(string.contains("\r\r\n"));
        if (string.contains("\n")) {
            assertEquals(string.inclusions("\r\n").size, string.inclusions("\n").size);
        }
    } finally {
        f.delete();
    }
}
