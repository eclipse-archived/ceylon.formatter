import java.io { ... }
import java.lang { System { sysin=\iin } }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer, CeylonParser }
import org.antlr.runtime { CharStream, ANTLRFileStream, ANTLRInputStream, CommonTokenStream, BufferedTokenStream }
import com.redhat.ceylon.compiler.typechecker.tree { Tree }
import ceylon.time { ... }
import ceylon.file { Writer, Resource, Path, parsePath, Directory, File, Nil, Link, Visitor }
import ceylon.formatter.options { FormattingOptions, commandLineOptions }
import ceylon.collection { MutableMap, HashMap }

"Run the module `ceylon.formatter`."
shared void run() {
    variable [FormattingOptions, String[]] options = commandLineOptions();
    if (exists inFileName = options[1][0], options[1].size == 1) {
        // input = output
        options = [options[0], [inFileName, inFileName]];
    }
    {<CharStream->Writer>*} files;
    switch (options[1].size<=>2)
    case (smaller) {
        // no input or output files, pipe mode
        object sysoutWriter satisfies Writer {
            shared actual void destroy() => flush();
            shared actual void flush() => process.flush();
            shared actual void write(String string) => process.write(string);
            shared actual void writeLine(String line) => process.writeLine(line);
        }
        files = { ANTLRInputStream(sysin)->sysoutWriter };
    }
    case (equal) {
        // read from first file, write to second file
        // or recursively from first directory to second directory
        assert(exists inFileName = options[1][0], exists outFileName = options[1][1]);
        if (is Directory dir = parsePath(inFileName).resource) {
            Directory target;
            Resource r = parsePath(outFileName).resource;
            if (is Directory r){
                target = r;
            } else if (is Nil r) {
                target = r.createDirectory();
            } else {
                throw Exception("Can’t format files from source directory '``inFileName``' to target resource '``outFileName``'!");
            }
            MutableMap<CharStream, Writer> mutableFiles = HashMap<CharStream, Writer>();
            dir.path.visit {
                object visitor extends Visitor() {
                    shared actual void file(File file) {
                        if(file.name.endsWith(".ceylon")) {
                            mutableFiles.put(ANTLRFileStream(file.path.string), parseFile(parsePath(outFileName).childPath(file.path.relativePath(file.path.elementPaths.first else nothing))).Overwriter());
                        }
                    }
                }
            };
            files = mutableFiles;
        } else {
            files = { ANTLRFileStream(inFileName)->parseFile(outFileName).Overwriter() };
        }
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
                ANTLRFileStream(inFileName)->parseFile(outDir.childPath(inFileName)).Overwriter()
        };
    }
    Instant start = now();
    for (CharStream->Writer file in files) {
        Instant t1 = now();
        CeylonLexer lexer = CeylonLexer(file.key);
        Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        Instant t2 = now();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        value formattingVisitor = FormattingVisitor(BufferedTokenStream(lexer), file.item, options[0]);
        cu.visit(formattingVisitor);
        formattingVisitor.close();
        file.item.close(null);
        Instant t3 = now();
        process.writeErrorLine("Compiler: ``t1.durationTo(t2)``, formatter: ``t2.durationTo(t3)``");
    }
    Instant end = now();
    process.writeErrorLine("Total: ``start.durationTo(end).string``");
}

File parseFile(Path|String path) {
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
        variable File f;
        for(childP in parts.rest) {
            p = p.childPath(childP);
            Resource r = p.resource;
            switch(r)
            case (is File) {
                if (childP != lastPart) {
                    throw Exception("Output directory part '``p``' is a file!");
                }
                f = r;
                break;
            }
            case (is Nil) {
                if (childP == lastPart) {
                    f = r.createFile();
                    break;
                } else {
                    r.createDirectory();
                }
            }
            case (is Directory) {
                if (childP == lastPart) {
                    throw Exception("Output is a directory!");
                }
            }
            else { 
                throw Exception("Output is not a file!");
            }
        } else {
            value r = firstPart.resource;
            switch (r)
            case (is File) {
                f = r;
            }
            case (is Nil) {
                f = r.createFile();
            }
            else {
                throw Exception("Output is not a file!");
            }
        }
        file = f;
    }
    case (is File) {
        file = resolved;
    }
    return file;
}
