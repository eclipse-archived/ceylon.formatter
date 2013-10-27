import java.io { ... }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { ANTLRFileStream, CommonTokenStream, BufferedTokenStream }
import com.redhat.ceylon.compiler.typechecker.tree { Tree }
import ceylon.time { ... }
import ceylon.file { Writer, File, parsePath, Nil, Resource }
import ceylon.formatter.options { FormattingOptions }

"Run the module `ceylon.formatter`."
shared void run() {
    String fileName = process.arguments[0] else "../ceylon-walkthrough/source/en/01basics.ceylon";
    Writer output;
    if (exists outFile = process.arguments[1]) {
        Resource resource = parsePath(outFile).resource;
        if (is File resource) {
            output = resource.Overwriter();
        } else if (is Nil resource) {
            output = resource.createFile().Overwriter();
        }
        throw Exception("Argument 1 is a directory!");
    }
    else {
        object sysoutWriter satisfies Writer {
        	shared actual void destroy() => flush();        	
        	shared actual void flush() => process.flush();        	
        	shared actual void write(String string) => process.write(string);        	
        	shared actual void writeLine(String line) => process.write(string);            
        }
        output = sysoutWriter;
    }
    CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fileName));
    Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
    lexer.reset(); // FormattingVisitor needs to read the tokens again
    Instant start = now();
    cu.visit(FormattingVisitor(BufferedTokenStream(lexer), output, FormattingOptions()));
    Instant end = now();
    output.close(null);
    process.writeError(start.durationTo(end).string);
}