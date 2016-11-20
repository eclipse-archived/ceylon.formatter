import ceylon.file {
    Directory,
    File,
    Nil,
    Path,
    Writer,
    parsePath
}
import java.lang {
    System
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
