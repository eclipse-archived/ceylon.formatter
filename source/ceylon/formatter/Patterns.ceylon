import org.antlr.runtime { Token }


// TODO
// remove assertions before release; they’re probably useful for finding bugs,
// but impact performance negatively


void writeEquals(FormattingWriter writer, Token|String equals) {
    if(is Token equals) {
        assert (equals.text == "=");
    } else {
        assert (equals == "=");
    }
    writer.writeToken {
        equals;
        beforeToken = noLineBreak;
        afterToken = Indent(1);
        spaceBefore = true;
        spaceAfter = true;
    };
}

void writeModifier(FormattingWriter writer, Token modifier) {
    writer.writeToken {
        modifier;
        beforeToken = noLineBreak;
        spaceBefore = true;
        spaceAfter = true;
    };
}

void writeSemicolon(FormattingWriter writer, Token semicolon, FormattingWriter.FormattingContext context) {
    assert(semicolon.text == ";");
    writer.writeToken {
        semicolon;
        beforeToken = noLineBreak;
        afterToken = Indent(0);
        spaceBefore = false;
        spaceAfter = true;
        context;
    };
}
