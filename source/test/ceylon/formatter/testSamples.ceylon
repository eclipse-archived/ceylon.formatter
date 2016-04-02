import ceylon.test {
    assertEquals,
    fail,
    parameters,
    test
}
import ceylon.file {
    ...
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree {
        CompilationUnit
    }
}
import com.redhat.ceylon.compiler.typechecker.parser {
    CeylonLexer,
    CeylonParser
}
import org.antlr.runtime {
    ANTLRFileStream,
    CommonTokenStream,
    BufferedTokenStream
}
import ceylon.formatter {
    FormattingVisitor
}
import ceylon.formatter.options {
    FormattingOptions,
    formattingFile,
    combinedOptions,
    SparseFormattingOptions
}
import ceylon.collection {
    LinkedList
}

shared {String*} findTestFiles(Path rootPath = parsePath("test-samples")) {
    assert (is Directory root = rootPath.resource);
    LinkedList<String> testFiles = LinkedList<String>();
    testFiles.addAll(root.files("*.ceylon")*.path*.string);
    for (dir in root.childDirectories()) {
        testFiles.addAll(findTestFiles(dir.path));
    }
    return testFiles;
}


"Tests that the formatter transforms `<filename>.ceylon` into `<filename>.ceylon.formatted`.
 If a file `<filename>.ceylon.options` exists, it is used as an options file
 (see [[ceylon.formatter.options::formattingFile]])."
test
parameters (`function findTestFiles`) 
shared void testFile(String filename) {
    if (is File inputFile = parsePath(filename).resource,
        is File|Nil expectedResource = parsePath(filename + ".formatted").resource) {
        File expectedFile;
        switch (expectedResource)
        case (is File) { expectedFile = expectedResource; }
        case (is Nil) { expectedFile = inputFile; }
        // format input file
        object output satisfies Writer {
            StringBuilder content = StringBuilder();
            shared actual void close() => flush();
            shared actual void flush() {}
            shared actual void write(String string) => content.append(string);
            shared actual void writeLine(String line) => content.append(line).appendNewline();
            shared actual String string => content.string;
            shared actual void writeBytes({Byte*} bytes) {
                throw AssertionError("Can’t write bytes");
            }
        }
        CeylonLexer lexer = CeylonLexer(ANTLRFileStream(filename));
        CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        FormattingOptions options;
        if (is File optionsFile = parsePath(filename + ".options").resource) {
            options = formattingFile(optionsFile.path.string);
        } else {
            options = FormattingOptions();
        }
        try (visitor = FormattingVisitor(BufferedTokenStream(lexer), // don't use CommonTokenStream - we don't want to skip comments
            output, combinedOptions(options, SparseFormattingOptions {
                    failFast = true;
                }))) {
            cu.visit(visitor);
        }
        variable String actual = output.string;
        // read expected file
        variable String expected = "";
        try (reader = expectedFile.Reader()) {
            while (exists line = reader.readLine()) {
                expected += line;
                expected += "\n";
            }
        }
        // mild reformatting of actual:
        // * newline goodness
        actual = actual.replace("\r\n", "\n").replace("\r", "\n");
        // * trailing newline
        if (!actual.endsWith("\n")) {
            actual += "\n";
        } else if (actual.endsWith("\n\n")) {
            // remove last trailing newline
            actual = actual[0 .. actual.size-2];
        }
        // now test that they're equal
        assertEquals(actual, expected);
    } else {
        fail("File ``parsePath(filename).absolutePath.string`` not found!");
    }
}
