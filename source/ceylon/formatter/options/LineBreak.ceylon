shared abstract class LineBreak(text, string) of os | lf | crlf {
    "The actual text of the line break, i. e.,
     what should be written to the file."
    shared String text;
    "The name of the object, i. e., one of
     `os`, `lf`, `crlf`."
    shared actual String string;
}

shared object os extends LineBreak(operatingSystem.newline, "os") {}
shared object lf extends LineBreak("\n", "lf") {}
shared object crlf extends LineBreak("\r\n", "crlf") {}
