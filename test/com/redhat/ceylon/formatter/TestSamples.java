package com.redhat.ceylon.formatter;

import java.io.IOException;
import java.io.StringWriter;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import org.antlr.runtime.ANTLRFileStream;
import org.antlr.runtime.BufferedTokenStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.junit.Assert;
import org.junit.Test;

import com.redhat.ceylon.compiler.typechecker.parser.CeylonLexer;
import com.redhat.ceylon.compiler.typechecker.parser.CeylonParser;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.CompilationUnit;

// JUnit doesn't like static methods, so although none of the test methods require an object reference, we can't make
// them static.
@SuppressWarnings("static-method")
public class TestSamples {

	/**
	 * Tests that the formatter transforms <tt>test/&lt;filename&gt;.ceylon</tt> into
	 * <tt>test/&lt;filename&gt;.ceylon.formatted</tt>.
	 * 
	 * @param filename
	 *            The name of the unformatted file.
	 */
	private static void testFile(String filename) {
		filename = "test/" + filename + ".ceylon";
		String actual;

		try (StringWriter output = new StringWriter((int) Files.size(Paths.get(filename)))) {
			CeylonLexer lexer = new CeylonLexer(new ANTLRFileStream(filename));
			CompilationUnit cu = new CeylonParser(new CommonTokenStream(lexer)).compilationUnit();
			lexer.reset(); // FormattingVisitor needs to read the tokens again
			cu.visit(new FormattingVisitor(new BufferedTokenStream(lexer), // can't use CommonTokenStream, we don't want
																			// to skip comments
					output));

			actual = output.toString();

			// http://stackoverflow.com/revisions/326440/7
			byte[] encoded = Files.readAllBytes(Paths.get(filename + ".formatted"));
			String expected = StandardCharsets.UTF_8.decode(ByteBuffer.wrap(encoded)).toString();

			// mild reformatting of expected and actual:
			// * newline goodness
			expected = expected.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
			actual = actual.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
			// * trailing newline
			if (expected.endsWith("\n"))
				expected = expected.substring(0, expected.length() - 1);
			if (actual.endsWith("\n"))
				actual = actual.substring(0, actual.length() - 1);
			Assert.assertEquals(expected, actual);
		}
		catch (IOException e) {
			throw new Error(e);
		}
		catch (RecognitionException e) {
			// This never actually happens, the compiler reports the error and then recovers
			Assert.fail("File \"" + filename + "\" couldn't be parsed! Exception:\n" + e.getMessage());
		}
	}

	@Test
	public void helloWorld() {
		testFile("helloWorld");
	}

	@Test
	public void helloWorldCommented() {
		testFile("helloWorldCommented");
	}
}
