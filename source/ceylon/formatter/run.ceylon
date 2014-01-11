import java.io { ... }
import java.lang { System { sysin=\iin } }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { CharStream, ANTLRFileStream, ANTLRInputStream, CommonTokenStream, BufferedTokenStream }
import com.redhat.ceylon.compiler.typechecker.tree { Tree }
import ceylon.time { ... }
import ceylon.file { Writer, Resource, Path, parsePath, Directory, File, Nil, Link }
import ceylon.formatter.options { FormattingOptions, commandLineOptions }

"Run the module `ceylon.formatter`."
shared void run() {
    [FormattingOptions, String[]] options = commandLineOptions();
    {<CharStream->Writer>*} files;
    switch (options[1].size<=>2)
    case (smaller) {
        // one or zero input files, write to stdout
        object sysoutWriter satisfies Writer {
            shared actual void destroy() => flush();
            shared actual void flush() => process.flush();
            shared actual void write(String string) => process.write(string);
            shared actual void writeLine(String line) => process.writeLine(line);
        }
        if (exists inFileName = options[1][0]) {
            files = { ANTLRFileStream(inFileName)->sysoutWriter };
        } else {
            files = { ANTLRInputStream(sysin)->sysoutWriter };
        }
    }
    case (equal) {
        // read from first file, write to second file
        assert(exists inFileName = options[1][0], exists outFileName = options[1][1]);
        files = { ANTLRFileStream(inFileName)->file(outFileName).Overwriter() };
    }
    case (larger) {
        // read from first..second-to-last file, write to last directory
        assert (exists String outDirName = options[1].last);
        Path outDir = parsePath(outDirName);
        variable value dir = outDir.resource;
        if (is Link d = dir) {
            dir = d.linkedResource;
        }
        value finalDir = dir;
        switch(finalDir)
        case (is Nil) {
            finalDir.createDirectory();
        }
        case (is File) {
            throw Exception("Output directory '``outDirName``' is a file!");
        }
        else { }
        files = {
            for (inFileName in options[1].initial(options[1].size-1))
                ANTLRFileStream(inFileName)->file(outDir.childPath(inFileName)).Overwriter()
        };
    }
    Instant start = now();
    for (CharStream->Writer file in files) {
        CeylonLexer lexer = CeylonLexer(file.key);
        Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        cu.visit(FormattingVisitor(BufferedTokenStream(lexer), file.item, options[0]));
        file.item.close(null);
    }
    Instant end = now();
    process.writeErrorLine(start.durationTo(end).string);
}

File file(Path|String path) {
    Resource output =  parsePath(path.string).resource;
    File|Directory|Nil resolved;
    if (is Link i = output) {
        resolved = i.linkedResource;
    } else {
        assert (is File|Directory|Nil output); // ceylon/ceylon-spec#74
        resolved = output;
    }
    File file;
    switch (resolved)
    case (is Directory) {
        throw Exception("Output file '``path``' is a directory!");
    }
    case (is Nil) {
        // recursively create file and parents
        value parts = resolved.path.elementPaths;
        assert (exists firstPart = parts.first, exists lastPart = parts.last);
        variable Path p = firstPart;
        for(childP in parts.rest) {
            p = p.childPath(childP);
            Resource r = p.resource;
            switch(r)
            case (is File) {
                if (childP != lastPart) {
                    throw Exception("Output directory part '``p``' is a file!");
                }
            }
            case (is Nil) {
                if (childP == lastPart) {
                    r.createFile();
                } else {
                    r.createDirectory();
                }
            }
            else { }
        }
        assert (is File f = p.resource);
        file = f;
    }
    case (is File) {
        file = resolved;
    }
    return file;
}
