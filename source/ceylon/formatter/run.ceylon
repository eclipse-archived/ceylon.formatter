import java.io { ... }
import java.lang {
    System {
        sysin=\iin
    }
}
import com.redhat.ceylon.compiler.typechecker.parser {
    CeylonLexer,
    CeylonParser
}
import org.antlr.runtime {
    CharStream,
    ANTLRFileStream,
    ANTLRInputStream,
    CommonTokenStream,
    BufferedTokenStream
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree
}
import ceylon.time { ... }
import ceylon.file {
    Writer,
    Resource,
    Path,
    parsePath,
    Directory,
    File,
    Nil,
    Link,
    Visitor
}
import ceylon.formatter.options {
    FormattingOptions,
    commandLineOptions
}

void noop(Anything* args) {}
void recoveryOnError(ANTLRFileStream stream, File file)(Throwable t) {
    t.printStackTrace();
    try (overwriter = file.Overwriter()) {
        overwriter.write(stream.substring(0, stream.size() - 1));
    }
}

void createParentDirectories(Nil nil) {
    value parts = nil.path.elementPaths;
    assert (nonempty parts);
    if (parts.size == 1) {
        return;
    }
    value initial = parts.first.resource;
    assert (is Directory|Nil initial);
    variable Directory current;
    switch (initial)
    case (is Directory) {
        current = initial;
    }
    case (is Nil) {
        current = initial.createDirectory();
    }
    for (part in parts.rest[... parts.size - 3]) {
        value next = current.path.childPath(part).resource.linkedResource;
        assert (is Directory|Nil next);
        switch (next)
        case (is Directory) {
            current = next;
        }
        case (is Nil) {
            current = next.createDirectory();
        }
    }
}

"Parses a list of paths from the command line.
 Returns a sequence of tuples of source [[CharStream]], target [[Writer]] and onError callback."
[CharStream, Writer(), Anything(Throwable)][] commandLineFiles(String[] arguments) {
    
    if (nonempty arguments) {
        variable Integer i = 0;
        variable SequenceAppender<String>? currentSources = null;
        SequenceBuilder<String[]->String> translations = SequenceBuilder<String[]->String>();
        while (i < arguments.size) {
            assert (exists argument = arguments[i]);
            value nextArgument = arguments[i + 1];
            if (argument == "--and") {
                if (exists nextArgument) {
                    if (exists current = currentSources) {
                        current.append(nextArgument);
                    } else {
                        process.writeErrorLine("Missing first file or directory before '--and ``nextArgument``'!");
                    }
                    i++;
                } else {
                    process.writeErrorLine("Missing file or directory after '--and'!");
                }
            } else if (argument == "--to") {
                if (exists nextArgument) {
                    if (exists current = currentSources) {
                        translations.append(current.sequence->nextArgument);
                    } else {
                        process.writeErrorLine("Missing files or directories before '--to ``nextArgument``'!");
                    }
                    i++;
                } else {
                    process.writeErrorLine("Missing file or directory after '--to'!");
                }
            } else {
                if (exists current = currentSources) {
                    if (current.size > 1) {
                        process.writeErrorLine("Warning: Multiple files or directories collected with '--and', but not redirected with '--to'!");
                    }
                    for (fileOrDir in current.sequence) {
                        translations.append([fileOrDir]->fileOrDir);
                    }
                }
                currentSources = SequenceAppender { argument };
            }
            i++;
        }
        if (exists current = currentSources) {
            if (current.size > 1) {
                process.writeErrorLine("Warning: Multiple files or directories collected with '--and', but not redirected with '--to'!");
            }
            for (fileOrDir in current.sequence) {
                translations.append([fileOrDir]->fileOrDir);
            }
        }
        value ret = SequenceBuilder<[CharStream, Writer(), Anything(Throwable)]>();
        void translate(String source, Directory targetDirectory) {
            value resource = parsePath(source).resource.linkedResource;
            object visitor extends Visitor() {
                shared actual void file(File file) {
                    if (file.name.endsWith(".ceylon")) {
                        value firstPart = file.path.elementPaths.first;
                        assert (exists firstPart);
                        value target = targetDirectory.path.childPath(file.path.relativePath(firstPart)).resource.linkedResource;
                        File targetFile;
                        switch (target)
                        case (is File) {
                            targetFile = target;
                        }
                        case (is Nil) {
                            try {
                                createParentDirectories(target);
                            } catch (AssertionError e) {
                                process.writeErrorLine("Can’t create target file '``target.path``'!");
                                return;
                            }
                            targetFile = target.createFile();
                        }
                        case (is Directory) {
                            process.writeErrorLine("Can’t format file '``source``' to target directory '``target.path``'!");
                            return;
                        }
                        value stream = ANTLRFileStream(file.path.string);
                        ret.append([stream, () => targetFile.Overwriter(), recoveryOnError(stream, targetFile)]);
                    }
                }
            }
            switch (resource)
            case (is Directory) {
                resource.path.visit {
                    visitor = visitor;
                };
            }
            case (is File) {
                visitor.file(resource);
            }
            case (is Nil) {
                process.writeErrorLine("Warning: Source file '``source``' doesn’t exist, skipping!");
            }
        }
        void translateToDirectory([String+] sources, Directory targetDirectory) {
            if (sources.size == 1) {
                // source/foo/bar → target/foo/bar
                translate(sources.first, targetDirectory);
            } else {
                // source1/foo/bar → target/source1/foo/bar, source2/baz → target/source2/baz
                for (source in sources) {
                    value resource = parsePath(source).resource.linkedResource;
                    Path targetPath;
                    switch (resource)
                    case (is Directory|Nil) {
                        targetPath = targetDirectory.path.childPath(source);
                    }
                    case (is File) {
                        targetPath = targetDirectory.path.childPath(resource.directory.path);
                    }
                    value targetResource = targetPath.resource.linkedResource;
                    switch (targetResource)
                    case (is Directory) {
                        translate(source, targetResource);
                    }
                    case (is Nil) {
                        try {
                            createParentDirectories(targetResource);
                        } catch (AssertionError e) {
                            process.writeErrorLine("Can’t create target directory '``targetPath``'!");
                            continue;
                        }
                        translate(source, targetResource.createDirectory());
                    }
                    case (is File) {
                        process.writeErrorLine("Can’t format source '``source``' to target file '``targetPath``'!");
                    }
                }
            }
        }
        variable Boolean printedAbsoluteFilePathsError = false;
        value translationsS = translations.sequence.select((String[]->String translation) {
                if (translation.key.any(compose(Path.absolute, parsePath))) {
                    // TODO support absolute file paths
                    if (!printedAbsoluteFilePathsError) {
                        process.writeErrorLine("Absolute file paths are currently not supported! (Issue #48)");
                        process.writeErrorLine("Skipping the following translation(s):");
                        printedAbsoluteFilePathsError = true;
                    }
                    process.writeErrorLine(translation.string);
                    return false;
                }
                return true;
            });
        for (translation in translationsS) {
            assert (nonempty sources = translation.key);
            value target = translation.item;
            value targetResource = parsePath(target).resource.linkedResource;
            switch (targetResource)
            case (is File) {
                if (is File sourceFile = parsePath(sources.first).resource.linkedResource) {
                    if (sources.size == 1) {
                        value stream = ANTLRFileStream(sources.first);
                        ret.append([stream, () => targetResource.Overwriter(), recoveryOnError(stream, targetResource)]);
                    } else {
                        process.writeErrorLine("Can’t format more than one source files or directories into a single target file!");
                        process.writeErrorLine("Skipping directive '``" --and ".join(sources)`` --to ``target``'.");
                    }
                } else {
                    process.writeErrorLine("Can’t format a source directory into a target file!");
                    process.writeErrorLine("Skipping directive '``" --and ".join(sources)`` --to ``target``'.");
                }
            }
            case (is Directory) {
                translateToDirectory(sources, targetResource);
            }
            case (is Nil) {
                if (is File sourceFile = parsePath(sources.first).resource.linkedResource, sources.size == 1) {
                    // single file to single file
                    value stream = ANTLRFileStream(sources.first);
                    try {
                        createParentDirectories(targetResource);
                    } catch (AssertionError e) {
                        process.writeErrorLine("Can’t create target file '``target``'!");
                    }
                    value targetFile = targetResource.createFile();
                    ret.append([stream, () => targetFile.Overwriter(), recoveryOnError(stream, targetFile)]);
                } else {
                    try {
                        createParentDirectories(targetResource);
                    } catch (AssertionError e) {
                        process.writeErrorLine("Can’t create target directory '``target``'!");
                    }
                    Directory targetDirectory = targetResource.createDirectory();
                    translateToDirectory(sources, targetDirectory);
                }
            }
        }
        return ret.sequence;
    } else {
        // no input or output files, pipe mode
        object sysoutWriter satisfies Writer {
            shared actual void close() => flush();
            shared actual void flush() => process.flush();
            shared actual void write(String string) => process.write(string);
            shared actual void writeLine(String line) => process.writeLine(line);
        }
        return [[ANTLRInputStream(sysin), () => sysoutWriter, noop]];
    }
}

"Run the module `ceylon.formatter`."
shared void run() {
    variable [FormattingOptions, String[]] options = commandLineOptions();
    if (exists inFileName = options[1][0], options[1].size == 1) {
        // input = output
        options = [options[0], [inFileName, inFileName]];
    }
    {[CharStream, Writer(), Anything(Throwable)]*} files = commandLineFiles(options[1]);
    Instant start = now();
    for ([CharStream, Writer(), Anything(Throwable)] file in files) {
        Instant t1 = now();
        CeylonLexer lexer = CeylonLexer(file[0]);
        Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        Instant t2 = now();
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        try {
            format(cu, options[0], file[1](), BufferedTokenStream(lexer));
        } catch (Throwable t) {
            file[2](t);
        }
        Instant t3 = now();
        if (options[0].measureTime) {
            process.writeErrorLine("Compiler: ``t1.durationTo(t2)``, formatter: ``t2.durationTo(t3)``");
        }
    }
    Instant end = now();
    if (options[0].measureTime) {
        process.writeErrorLine("Total: ``start.durationTo(end).string``");
    }
}
