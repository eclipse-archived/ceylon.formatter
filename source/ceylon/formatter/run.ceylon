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
import ceylon.file {
    Writer,
    Path,
    parsePath,
    Directory,
    File,
    Nil,
    Visitor
}
import ceylon.collection {
    MutableList,
    LinkedList
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

"Creates all parent directories in a path (but not the [[nil]] resource itself)."
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

"Determines the common root of several paths.
 For example, the common root of `a/b/c` and `a/b/d` is `a/b`,
 the common root of `/a/b/c` and `/a/d/e` is `/a`
 and the common root of `a` and `b` is the empty path."
Path commonRoot(
    "The paths. Must be either all absolute or all relative."
    variable [Path+] paths) {
    Boolean allAbsolute = paths.every(Path.absolute);
    "Can’t mix absolute and relative paths"
    assert (allAbsolute || paths.every(not(Path.absolute)));
    variable Path root;
    if (allAbsolute) {
        root = parsePath(paths.first.separator);
    } else {
        root = parsePath("");
    }
    value iterators = paths.collect((Path p) => p.elementPaths.iterator());
    function nextOrNull<Element>(Iterator<Element> it) {
        if (is Element element = it.next()) {
            return element;
        }
        return null;
    }
    variable [Path?+] parts = iterators.collect(nextOrNull<Path>);
    while (parts.every((Path? p) => p exists) && parts.filter((Path? p) {
                assert (exists first = parts.first, exists p);
                return first == p;
            }).size == parts.size) {
        assert (is Path firstPart = parts.first);
        root = root.childPath(firstPart);
        parts = iterators.collect(nextOrNull<Path>);
    }
    return root;
}

"Parses translations from the [[arguments]].
 
 For example, the arguments
 ~~~
 a/b/c --and a/b/d --to x/a/b   d/e   f/g --to m/n/f/g
 ~~~
 correspond to the translations
 ~~~
 [
   [a/b/c, a/b/d] -> x/a/b,
   d/e -> d/e,
   f/g -> m/n/f/g
 ]
 ~~~"
<String[]->String>[] parseTranslations(String[] arguments) {
    variable Integer i = 0;
    variable MutableList<String>? currentSources = null;
    MutableList<String[]->String> translations = LinkedList<String[]->String>();
    while (i < arguments.size) {
        assert (exists argument = arguments[i]);
        value nextArgument = arguments[i + 1];
        if (argument == "--and") {
            if (exists nextArgument) {
                if (exists current = currentSources) {
                    current.add(nextArgument);
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
                    translations.add(current.sequence()->nextArgument);
                    currentSources = null;
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
                for (fileOrDir in current.sequence()) {
                    translations.add([fileOrDir]->fileOrDir);
                }
            }
            currentSources = LinkedList { argument };
        }
        i++;
    }
    if (exists current = currentSources) {
        if (current.size > 1) {
            process.writeErrorLine("Warning: Multiple files or directories collected with '--and', but not redirected with '--to'!");
        }
        for (fileOrDir in current.sequence()) {
            translations.add([fileOrDir]->fileOrDir);
        }
    }
    return translations.sequence();
}

"Process a single source from a translation, that is:
 
 - recurse the file tree from [[source]]
 - for each file found, open a CharStream to read from it and a Writer to write to the correct file in [[targetDirectory]]
 - the target path is [[targetDirectory]] + (source path - [[root]])"
[CharStream, Writer(), Anything(Throwable)][] translateSingleSource(String source, Path root, Directory targetDirectory) {
    value ret = LinkedList<[CharStream, Writer(), Anything(Throwable)]>();
    object visitor extends Visitor() {
        shared actual void file(File file) {
            if (file.name.endsWith(".ceylon")) {
                value path = file.path;
                value uprootedPath = path.relativePath(root);
                value rerootedPath = targetDirectory.path.childPath(uprootedPath);
                value target = rerootedPath.resource.linkedResource;
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
                ret.add([stream, () => targetFile.Overwriter(), recoveryOnError(stream, targetFile)]);
            }
        }
    }
    value resource = parsePath(source).resource.linkedResource;
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
    return ret.sequence();
}

"Translate one or more sources to a target directory."
see (`function parseTranslations`)
[CharStream, Writer(), Anything(Throwable)][] translate([String+] sources, Directory targetDirectory) {
    value ret = LinkedList<[CharStream, Writer(), Anything(Throwable)]>();
    value root = commonRoot(sources.collect(parsePath));
    if (sources.size == 1) {
        // source/foo/bar → target/foo/bar
        ret.addAll(translateSingleSource(sources.first, root, targetDirectory));
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
                ret.addAll(translateSingleSource(source, root, targetResource));
            }
            case (is Nil) {
                try {
                    createParentDirectories(targetResource);
                } catch (AssertionError e) {
                    process.writeErrorLine("Can’t create target directory '``targetPath``'!");
                    continue;
                }
                ret.addAll(translateSingleSource(source, root, targetResource.createDirectory()));
            }
            case (is File) {
                process.writeErrorLine("Can’t format source '``source``' to target file '``targetPath``'!");
            }
        }
    }
    return ret.sequence();
}

"Parses a list of paths from the command line.
 Returns a sequence of tuples of source [[CharStream]], target [[Writer]] and onError callback."
[CharStream, Writer(), Anything(Throwable)][] commandLineFiles(String[] arguments) {
    if (nonempty arguments) {
        value ret = LinkedList<[CharStream, Writer(), Anything(Throwable)]>();
        
        for (translation in parseTranslations(arguments)) {
            assert (nonempty sources = translation.key);
            value target = translation.item;
            value targetResource = parsePath(target).resource.linkedResource;
            switch (targetResource)
            case (is File) {
                if (is File sourceFile = parsePath(sources.first).resource.linkedResource) {
                    if (sources.size == 1) {
                        value stream = ANTLRFileStream(sources.first);
                        ret.add([stream, () => targetResource.Overwriter(), recoveryOnError(stream, targetResource)]);
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
                ret.addAll(translate(sources, targetResource));
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
                    ret.add([stream, () => targetFile.Overwriter(), recoveryOnError(stream, targetFile)]);
                } else {
                    try {
                        createParentDirectories(targetResource);
                    } catch (AssertionError e) {
                        process.writeErrorLine("Can’t create target directory '``target``'!");
                    }
                    Directory targetDirectory = targetResource.createDirectory();
                    ret.addAll(translate(sources, targetDirectory));
                }
            }
        }
        return ret.sequence();
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
    variable Boolean measureTime = false;
    value fileArgs = options[1].select((String s) {
            if (s == "--measureTime") {
                measureTime = true;
                return false;
            }
            return true;
        });
    {[CharStream, Writer(), Anything(Throwable)]*} files = commandLineFiles(fileArgs);
    value start = system.milliseconds;
    for ([CharStream, Writer(), Anything(Throwable)] file in files) {
        value t1 = system.milliseconds;
        CeylonLexer lexer = CeylonLexer(file[0]);
        Tree.CompilationUnit cu = CeylonParser(CommonTokenStream(lexer)).compilationUnit();
        value t2 = system.milliseconds;
        lexer.reset(); // FormattingVisitor needs to read the tokens again
        try {
            format(cu, options[0], file[1](), BufferedTokenStream(lexer));
        } catch (Throwable t) {
            file[2](t);
        }
        value t3 = system.milliseconds;
        if (measureTime) {
            process.writeErrorLine("Compiler: `` t2 - t1 ``ms, formatter: `` t3 - t2 ``ms");
        }
    }
    value end = system.milliseconds;
    if (measureTime) {
        process.writeErrorLine("Total: `` end - start ``ms");
    }
}
