import ceylon.test {
    assertEquals,
    fail,
    test
}
import ceylon.file { ... }
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
    CombinedOptions,
    SparseFormattingOptions
}

"Tests that the formatter transforms `test-samples/<filename>.ceylon`
 into `test-samples/<filename>.ceylon.formatted`. If a file
 `test-samples/<filename>.ceylon.options` exists, it is used as an options file
 (see [[ceylon.formatter.options::formattingFile]])."
void testFile(String filename) {
    String fullFilename = "test-samples/" + filename + ".ceylon";
    if (is File inputFile = parsePath(fullFilename).resource,
        is File expectedFile = parsePath(fullFilename + ".formatted").resource) {
        // format input file
        object output satisfies Writer {
            StringBuilder content = StringBuilder();
            shared actual void destroy() => flush();
            shared actual void flush() {}
            shared actual void write(String string) => content.append(string);
            shared actual void writeLine(String line) => content.append(line).appendNewline();
            shared actual String string => content.string;
        }
        CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fullFilename));
        CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        FormattingOptions options;
        if (is File optionsFile = parsePath(fullFilename + ".options").resource) {
            options = formattingFile(optionsFile.path.string);
        } else {
            options = FormattingOptions();
        }
        FormattingVisitor visitor = FormattingVisitor(BufferedTokenStream(lexer), // don't use CommonTokenStream - we don't want to skip comments
            output, CombinedOptions(options, SparseFormattingOptions {
                    failFast = true;
                }));
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
        } else if (actual.endsWith("\n\n")) {
            // remove last trailing newline
            actual = actual[0 .. actual.size - 2];
        }
        // now test that they're equal
        assertEquals(actual, expected);
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

test
shared void testLongInvocation() {
    testFile("longInvocation");
}

test
shared void testBraceOnOwnLine() {
    testFile("braceOnOwnLine");
}

test
shared void testParamListParenWithSpaces() {
    testFile("paramListParenWithSpaces");
}

test
shared void testParamListParenWithoutSpaces() {
    testFile("paramListParenWithoutSpaces");
}

test
shared void testMultiLineString() {
    testFile("multiLineString");
}

test
shared void testMultiLineStringIndented() {
    testFile("multiLineStringIndented");
}

test
shared void testMemberOp() {
    testFile("memberOp");
}

test
shared void testAssignments() {
    testFile("assignments");
}

test
shared void testAnnotationsNoArguments() {
    testFile("annotationsNoArguments");
}

test
shared void testAnnotationsPositionalArguments() {
    testFile("annotationsPositionalArguments");
}

test
shared void testImportSingleLine() {
    testFile("importSingleLine");
}

test
shared void testImportMultiLine() {
    testFile("importMultiLine");
}

test
shared void testDoc() {
    testFile("doc");
}

test
shared void testTypes() {
    testFile("types");
}

test
shared void testGroupedTypes() {
    testFile("groupedTypes");
}

test
shared void testMultiLineParameterList() {
    testFile("multiLineParameterList");
}

test
shared void testSimpleClass() {
    testFile("simpleClass");
}

test
shared void testPositiveNegativeOp() {
    testFile("positiveNegativeOp");
}

test
shared void testSequencedArguments() {
    testFile("sequencedArguments");
}

test
shared void testRangeOp() {
    testFile("rangeOp");
}

test
shared void testAttributeGetterDeclaration() {
    testFile("attributeGetterDeclaration");
}

test
shared void testFor() {
    testFile("for");
}

test
shared void testIf() {
    testFile("if");
}

test
shared void testBinaryOperators() {
    testFile("binaryOperators");
}

test
shared void testPostfixOperators() {
    testFile("postfixOperators");
}

test
shared void testFunctionArguments() {
    testFile("functionArguments");
}

test
shared void testSwitch() {
    testFile("switch");
}

test
shared void testThrow() {
    testFile("throw");
}

test
shared void testStringTemplates() {
    testFile("stringTemplates");
}

test
shared void testNot() {
    testFile("not");
}

test
shared void testComprehensions() {
    testFile("comprehensions");
}

test
shared void testIndexExpressions() {
    testFile("indexExpressions");
}

test
shared void testObjects() {
    testFile("objects");
}

test
shared void testSelf() {
    testFile("self");
}

test
shared void testNamedArguments() {
    testFile("namedArguments");
}

test
shared void testIs() {
    testFile("is");
}

test
shared void testExpressions() {
    testFile("expressions");
}

test
shared void testReturn() {
    testFile("return");
}

test
shared void testExistsNonempty() {
    testFile("existsNonempty");
}

test
shared void testTuples() {
    testFile("tuples");
}

test
shared void testCaseTypes() {
    testFile("caseTypes");
}

test
shared void testInterfaces() {
    testFile("interfaces");
}

test
shared void testOuter() {
    testFile("outer");
}

test
shared void testTypeAliases() {
    testFile("typeAliases");
}

test
shared void testSpreadArguments() {
    testFile("spreadArguments");
}

test
shared void testTry() {
    testFile("try");
}

test
shared void testWhile() {
    testFile("while");
}

test
shared void testContinue() {
    testFile("continue");
}

test
shared void testBreak() {
    testFile("break");
}

test
shared void testWithinOps() {
    testFile("withinOps");
}

test
shared void testTypeOperatorExpressions() {
    testFile("typeOperatorExpressions");
}

test
shared void testFunctionTypes() {
    testFile("functionTypes");
}

test
shared void testPrefixOperators() {
    testFile("prefixOperators");
}

test
shared void testSmallBlocks() {
    testFile("smallBlocks");
}

test
shared void testCommentsAfterStatements() {
    testFile("commentsAfterStatements");
}

test
shared void testTypeArguments() {
    testFile("typeArguments");
}

test
shared void testTypeConstraints() {
    testFile("typeConstraints");
}

test
shared void testQualifiedMemberOrTypeExpressions() {
    testFile("qualifiedMemberOrTypeExpressions");
}

test
shared void testPackage() {
    testFile("package");
}

test
shared void testModule() {
    testFile("module");
}

test
shared void testObjectArguments() {
    testFile("objectArguments");
}

test
shared void testImportKeywords() {
    testFile("importKeywords");
}

test
shared void testComments() {
    testFile("comments");
}

test
shared void testComprehensionIndentation() {
    testFile("comprehensionIndentation");
}

test
shared void testRangeSpacing() {
    testFile("rangeSpacing");
}
