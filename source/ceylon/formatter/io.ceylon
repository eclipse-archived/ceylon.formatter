import ceylon.file {
    Directory,
    File,
    Nil,
    Path,
    Writer,
    parsePath
}
import ceylon.interop.java {
    javaClass
}
import java.lang {
    System
}
import java.nio.file {
    Files,
    Paths
}
import java.nio.file.attribute {
    PosixFileAttributeView
}
import org.antlr.runtime {
    ANTLRFileStream,
    ANTLRInputStream,
    CharStream
}

"Something that ANTLR can read from."
interface Readable {
    shared formal CharStream charStream;
}
"A real file on the file system."
class FileReadable(File file) satisfies Readable {
    shared actual ANTLRFileStream charStream => ANTLRFileStream(file.path.string);
}
"Standard input."
object stdin satisfies Readable {
    charStream => ANTLRInputStream(System.\iin);
}
"Something that we can write to."
interface Writable {
    shared formal Writer writer;
}
"A real file on the file system.
 The backing [[file]] may be accessed directly."
class FileWritable(shared File file) satisfies Writable {
    writer => file.Overwriter();
}
"Standard output."
object stdout satisfies Writable {
    writer => stdoutWriter;
}

"Parse a path into a resource for reading.
 `/dev/stdin` means [[standard input|stdin]], everything else resolves to [[resource]] (after resolving symlinks)."
Readable|Directory|Nil readableResource(String path) {
    if (path == "/dev/stdin") { return stdin; }
    switch (res = parsePath(path).resource.linkedResource)
    case (is File) { return FileReadable(res); }
    else { return res; }
}
"Parse a path into a resource for writing.
 `/dev/stdout` means [[standard output|stdout]], everything else resolves to [[resource]] (after resolving symlinks)."
Writable|Directory|Nil writableResource(String path) {
    if (path == "/dev/stdout") { return stdout; }
    switch (res = parsePath(path).resource.linkedResource)
    case (is File) { return FileWritable(res); }
    else { return res; }
}

"Create a file at [[target]], like [[Nil.createFile]].
 If [[reference]] exists, copy ownership information from there."
File createFile(Nil target, Boolean includingParentDirectories = false, String? reference = null) {
    try {
        if (is Nil parent = target.path.parent.resource) {
            createDirectory(parent, includingParentDirectories, reference);
        }
        value ret = target.createFile { includingParentDirectories = false; };
        copyOwnership { target = target.path.string; reference = reference; };
        return ret;
    } catch (Exception e) {
        return target.createFile { includingParentDirectories = includingParentDirectories; };
    }
}

"Create a directory at [[target]], like [[Nil.createDirectory]].
 If [[reference]] exists, try to copy ownership information from there."
Directory createDirectory(Nil target, Boolean includingParentDirectories = false, String? reference = null) {
    try {
        if (is Nil parent = target.path.parent.resource,
            parent.path != target.path) {
            createDirectory(parent, includingParentDirectories, reference);
        }
        value ret = target.createDirectory { includingParentDirectories = false; };
        copyOwnership { target = target.path.string; reference = reference; };
        return ret;
    } catch (Exception e) {
        return target.createDirectory { includingParentDirectories = includingParentDirectories; };
    }
}

"Try to copy ownership information from the reference path to the target path.
 The information includes the owner and,
 if the file system supports it, the group.
 If [[reference]] is [[null]], or if any exception occurs,
 silently do nothing."
void copyOwnership(String target, String? reference) {
    try {
        if (exists reference) {
            value targetPath = Paths.get(target);
            value referencePath = Paths.get(reference);
            // copy owner
            value targetOwner = Files.getOwner(targetPath);
            value referenceOwner = Files.getOwner(referencePath);
            if (targetOwner != referenceOwner) {
                Files.setOwner(targetPath, referenceOwner);
            }
            if (exists targetView = Files.getFileAttributeView(targetPath, javaClass<PosixFileAttributeView>()),
                exists referenceView = Files.getFileAttributeView(referencePath, javaClass<PosixFileAttributeView>())) {
                // copy group
                value targetAttributes = targetView.readAttributes();
                value referenceAttributes = referenceView.readAttributes();
                if (targetAttributes.group() != referenceAttributes.group()) {
                    targetView.setGroup(referenceAttributes.group());
                }
            }
        }
    } catch (Exception e) {
        // ignore
    }
}
