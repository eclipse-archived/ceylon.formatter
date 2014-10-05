import ceylon.test {
    test
}
import ceylon.formatter {
    FormattingWriter,
    maxDesire
}
import ceylon.formatter.options {
    parseLineBreakStrategy,
    FormattingOptions,
    LineBreakStrategy
}
import ceylon.file {
    Writer
}
import ceylon.collection {
    MutableList,
    LinkedList
}

test
shared void testDefaultLineBreaks() {
    object writer satisfies Writer {
        shared actual void close() {}
        shared actual void flush() {}
        shared actual void write(String string) {}
        shared actual void writeLine(String line) {}
        shared actual void writeBytes({Byte*} bytes) {}
    }
    FormattingWriter w = FormattingWriter(null, writer, FormattingOptions());
    
    LineBreakStrategy? defaultLineBreaks = parseLineBreakStrategy("default");
    assert (exists defaultLineBreaks);
    
    assert (exists location1 = defaultLineBreaks.lineBreakLocation([
                w.Token("breakHere", false, 1, maxDesire, maxDesire),
                *{
                    for (i in 1..10)
                        w.Token("noBreakHere``i``", true, null, maxDesire, maxDesire)
                }], 0, 20), location1 == 1);
    
    assert (is Null n = defaultLineBreaks.lineBreakLocation([
                for (i in 1..10)
                    w.Token("noBreakHere``i``", false, null, maxDesire, maxDesire)
            ], 0, 20));
    
    MutableList<FormattingWriter.QueueElement> s = LinkedList<FormattingWriter.QueueElement>();
    for (i in 1..10) {
        s.add(w.Token("noBreakHere``i``", false, null, maxDesire, maxDesire));
    }
    s.add(w.LineBreak());
    assert (exists location2 = defaultLineBreaks.lineBreakLocation(s.sequence(), 0, 20), location2 == 10);
}
