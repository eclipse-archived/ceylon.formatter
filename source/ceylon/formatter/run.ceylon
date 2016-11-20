import java.io {
    ...
}
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
    Resource,
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

"Determines the common root of several paths.
 For example, the common root of `a/b/c` and `a/b/d` is `a/b`,
 the common root of `/a/b/c` and `/a/d/e` is `/a`
 and the common root of `a` and `b` is the empty path."
shared Path commonRoot(
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
            }).size==parts.size) {
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
 ~~~
 
 The special argument `--pipe` corresponds to a translation `[/dev/stdin] -> /dev/stdout`."
shared <String[]->String>[] parseTranslations(String[] arguments) {
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
                    translations.add(current.sequence() -> nextArgument);
                    currentSources = null;
                } else {
                    process.writeErrorLine("Missing files or directories before '--to ``nextArgument``'!");
                }
                i++;
            } else {
                process.writeErrorLine("Missing file or directory after '--to'!");
            }
        } else if (argument == "--pipe") {
            if (exists current = currentSources) {
                if (current.size > 1) {
                    process.writeErrorLine("Warning: Multiple files or directories collected with '--and', but not redirected with '--to'!");
                }
                for (fileOrDir in current.sequence()) {
                    translations.add([fileOrDir] -> fileOrDir);
                }
                currentSources = null;
            }
            translations.add(["/dev/stdin"] -> "/dev/stdout");
        } else {
            if (exists current = currentSources) {
                if (current.size > 1) {
                    process.writeErrorLine("Warning: Multiple files or directories collected with '--and', but not redirected with '--to'!");
                }
                for (fileOrDir in current.sequence()) {
                    translations.add([fileOrDir] -> fileOrDir);
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
            translations.add([fileOrDir] -> fileOrDir);
        }
    }
    return translations.sequence();
}

"Process a single source from a translation, that is:
 
 - recurse the file tree from [[source]]
 - for each file found, open a CharStream to read from it and a Writer to write to the correct file in [[target]]
 - the target path is [[target]] + (source path - [[root]])"
[CharStream, Writer(), Anything(Throwable)][] translateSingleSource(String source, Path root, Resource target) {
    value ret = LinkedList<[CharStream, Writer(), Anything(Throwable)]>();
    object visitor extends Visitor() {
        shared actual void file(File file) {
            if (file.name.endsWith(".ceylon")) {
                value path = file.path;
                value uprootedPath = path.relativePath(root);
                value rerootedPath = target.path.childPath(uprootedPath);
                value targetResource = rerootedPath.resource.linkedResource;
                File targetFile;
                switch (targetResource)
                case (is File) {
                    targetFile = targetResource;
                }
                case (is Nil) {
                    targetFile = targetResource.createFile { includingParentDirectories = true; };
                }
                case (is Directory) {
                    process.writeErrorLine("Can’t format file '``source``' to target directory '``targetResource.path``'!");
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

"Translate one or more sources to a target."
see (`function parseTranslations`)
[CharStream, Writer(), Anything(Throwable)][] translate([String+] sources, Resource target)
        => let (root = commonRoot(sources.collect(parsePath)))
            concatenate(for (source in sources) translateSingleSource(source, root, target));

"Parses a list of paths from the command line.
 Returns a sequence of tuples of source [[CharStream]], target [[Writer]] and onError callback."
[CharStream, Writer(), Anything(Throwable)][] commandLineFiles(variable String[] arguments) {
    value ret = LinkedList<[CharStream, Writer(), Anything(Throwable)]>();
    
    if (arguments.empty) {
        arguments = ["--pipe"];
    }
    
    for (translation in parseTranslations(arguments)) {
        assert (nonempty sources = translation.key);
        value target = translation.item;
        value targetResource = writableResource(target);
        if (is Writable targetResource) {
            // single file to single existing file
            if (is Readable sourceReadable = readableResource(sources.first)) {
                if (sources.size == 1) {
                    value recovery = if (is FileReadable sourceReadable, is FileWritable targetResource) then recoveryOnError(sourceReadable.charStream, targetResource.file) else noop;
                    ret.add([sourceReadable.charStream, () => targetResource.writer, recovery]);
                } else {
                    process.writeErrorLine("Can’t format more than one source files or directories into a single target file!");
                    process.writeErrorLine("Skipping directive '``" --and ".join(sources)`` --to ``target``'.");
                }
            } else {
                process.writeErrorLine("Can’t format a source directory into a target file!");
                process.writeErrorLine("Skipping directive '``" --and ".join(sources)`` --to ``target``'.");
            }
        } else if (is Directory targetResource) {
            // one or more files to existing directory
            ret.addAll(translate(sources, targetResource));
        } else {
            if (sources.size == 1, is Readable sourceReadable = readableResource(sources.first)) {
                // single file to single new file
                value targetFile = targetResource.createFile { includingParentDirectories = true; };
                value recovery = if (is FileReadable sourceReadable) then recoveryOnError(sourceReadable.charStream, targetFile) else noop;
                ret.add([sourceReadable.charStream, () => targetFile.Overwriter(), recovery]);
            } else {
                // one or more files to new directory
                ret.addAll(translate(sources, targetResource));
            }
        }
    }
    return ret.sequence();
}

"Run the module `ceylon.formatter`."
shared void run(String[] arguments = process.arguments) {
    variable [FormattingOptions, String[]] options = commandLineOptions(arguments);
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
