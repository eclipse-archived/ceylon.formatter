import ceylon.test { assertEquals, fail, test }
import ceylon.file { ... }
import com.redhat.ceylon.compiler.typechecker.tree { Tree { CompilationUnit } }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { ANTLRFileStream, CommonTokenStream, BufferedTokenStream }
import ceylon.formatter { FormattingVisitor }
import ceylon.formatter.options { FormattingOptions }

"Tests that the formatter transforms `test-samples/<filename>.ceylon`
 into `test-samples/<filename>.ceylon.formatted`."
void testFile(String filename) {
    String fullFilename = "test-samples/" + filename + ".ceylon";
    if(is File inputFile =  parsePath(fullFilename).resource,
        is File expectedFile = parsePath(fullFilename + ".formatted").resource) {
        // format input file
        object output satisfies Writer {            
            variable String content = "";
            shared actual void destroy() => flush();            
            shared actual void flush() {}            
            shared actual void write(String string) => content += string;            
            shared actual void writeLine(String line) => content += line + operatingSystem.newline;            
            shared actual String string => content;            
        }
        CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fullFilename));
        CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        FormattingVisitor visitor = FormattingVisitor(BufferedTokenStream(lexer), // don't use CommonTokenStream - we don't want to skip comments
            output, FormattingOptions());
        cu.visit(visitor);
        visitor.close();
        variable String actual = output.string;
        // read expected file
        variable String expected = "";
        value reader = expectedFile.Reader();
        while (exists line = reader.readLine()) {
            expected += line;
            expected += "\n";
        }
        reader.destroy();
        // mild reformatting of actual:
        // * newline goodness
        actual = actual.replace("\r\n", "\n").replace("\r", "\n");
        // * trailing newline
        if (!actual.endsWith("\n")) {
            actual += "\n";
        }
        // now test that they're equal
        assertEquals(expected, actual);
    } else {
        fail("File ``parsePath(fullFilename).absolutePath.string`` not found!");
    }
}

test
shared void testHelloWorld() {
    testFile("helloWorld");
}

test
shared void testHelloWorldCommented() {
    testFile("helloWorldCommented");
}