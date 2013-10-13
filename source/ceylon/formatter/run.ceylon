import java.lang { System { sysout=\iout, syserr=err } }
import java.io { ... }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { ANTLRFileStream, CommonTokenStream, BufferedTokenStream }
import com.redhat.ceylon.compiler.typechecker.tree { Tree }
import ceylon.time { ... }
import ceylon.formatter.options { defaultOptions }

"Run the module `ceylon.formatter`."
shared void run() {
    String fileName = process.arguments[0] else "../ceylon-walkthrough/source/en/01basics.ceylon";
    Writer output;
    if (exists outFile = process.arguments[1]) {
        output = FileWriter(outFile);
    }
    else {
        output = OutputStreamWriter(sysout);
    }
    CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fileName));
    Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
    lexer.reset(); // FormattingVisitor needs to read the tokens again
    Instant start = now();
    cu.visit(FormattingVisitor(BufferedTokenStream(lexer), output, defaultOptions));
    Instant end = now();
    output.close();
    syserr.println(start.durationTo(end).string);
}