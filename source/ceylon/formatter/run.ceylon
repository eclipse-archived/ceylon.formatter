import java.io { ... }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { ANTLRFileStream, CommonTokenStream, BufferedTokenStream }
import com.redhat.ceylon.compiler.typechecker.tree { Tree }
import ceylon.time { ... }
import ceylon.file { Writer, File, parsePath, Nil, Resource }
import ceylon.formatter.options { FormattingOptions, commandLineOptions }

"Run the module `ceylon.formatter`."
shared void run() {
    [FormattingOptions, String[]] options = commandLineOptions();
    String? fileName = options[1][0];
    if (exists fileName) {
        Resource resource = parsePath(fileName).resource;
        if (!is File resource) {
            throw Exception("Input file '``fileName``' isn’t a regular file!");
        }
    } else {
        throw Exception("Missing input file name!");
    }
    Writer output;
    if (exists outFile = options[1][1]) {
        Resource resource = parsePath(outFile).resource;
        if (is File resource) {
            output = resource.Overwriter();
        } else if (is Nil resource) {
            output = resource.createFile().Overwriter();
        } else {
            throw Exception("Output file '``outFile``' is a directory!");
        }
    }
    else {
        object sysoutWriter satisfies Writer {
            shared actual void destroy() => flush();
            shared actual void flush() => process.flush();
            shared actual void write(String string) => process.write(string);
            shared actual void writeLine(String line) => process.writeLine(line);
        }
        output = sysoutWriter;
    }
    if(options[1].size > 2) {
        throw Exception("Extraneous argument!"); // TODO we could probably do cp-style SOURCE... DIRECTORY instead
    }
    CeylonLexer lexer = CeylonLexer(ANTLRFileStream(fileName));
    Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
    lexer.reset(); // FormattingVisitor needs to read the tokens again
    Instant start = now();
    cu.visit(FormattingVisitor(BufferedTokenStream(lexer), output, options[0]));
    Instant end = now();
    output.close(null);
    process.writeErrorLine(start.durationTo(end).string);
}