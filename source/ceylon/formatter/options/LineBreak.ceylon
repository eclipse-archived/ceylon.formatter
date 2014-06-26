shared abstract class LineBreak(shared actual String string) of os | lf | crlf {}

shared object os extends LineBreak(operatingSystem.newline) {}
shared object lf extends LineBreak("\n") {}
shared object crlf extends LineBreak("\r\n") {}
