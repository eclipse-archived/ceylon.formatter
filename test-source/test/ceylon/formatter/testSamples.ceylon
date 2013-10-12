import ceylon.test { assertEquals }
import ceylon.file { ... }
import java.io { StringWriter }
import com.redhat.ceylon.compiler.typechecker.tree { Tree { CompilationUnit } }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { ANTLRFileStream, CommonTokenStream, BufferedTokenStream }
import ceylon.formatter { FormattingVisitor }
import java.lang { Error }

"Tests that the formatter transforms `test-samples/<filename>.ceylon`
 into `test-samples/<filename>.ceylon.formatted`."
void testFile(String filename) {
	String fullFilename = "test-samples/" + filename + ".ceylon";
	if(is File inputFile =  parsePath(fullFilename).resource,
		is File expectedFile = parsePath(fullFilename + ".formatted").resource) {
		// format input file
		StringWriter output = StringWriter(inputFile.size);
		CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fullFilename));
		CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
		lexer.reset(); // FormattingVisitor needs to read the tokens again
		cu.visit(FormattingVisitor(BufferedTokenStream(lexer), // don't use CommonTokenStream - we don't want to skip comments
									output));
		variable String actual = output.string;
		// read expected file
		variable String expected = "";
		value reader = expectedFile.reader();
		while (exists line = reader.readLine()) {
			expected += line;
			expected += "\n";
		}
		reader.destroy();
		// mild reformatting of expected and actual:
		// * newline goodness
		actual = actual.replace("\r\n", "\n").replace("\r", "\n");
		// * trailing newline
		if (!expected.endsWith("\n")) {
			expected += "\n";
		}
		if (!actual.endsWith("\n")) {
			actual += "\n";
		}
		// now test that they're equal
		assertEquals(expected, actual);
	} else {
		throw Error("File ``parsePath(fullFilename).absolutePath.string`` not found!");
	}
}

shared void testHelloWorld() {
	testFile("helloWorld");
}

shared void testHelloWorldCommented() {
	testFile("helloWorldCommented");
}