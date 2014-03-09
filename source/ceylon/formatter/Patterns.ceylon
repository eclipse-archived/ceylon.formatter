import org.antlr.runtime { Token }
import com.redhat.ceylon.compiler.typechecker.tree { Tree { ... } }
import ceylon.formatter.options { LineBreakStrategy }


// TODO
// remove assertions before release; they’re probably useful for finding bugs,
// but impact performance negatively


FormattingWriter.FormattingContext writeBacktickOpening(FormattingWriter writer, Token backtick) {
    assert (backtick.text == "`");
    value context = writer.writeToken {
        backtick;
        linebreaksAfter = noLineBreak;
        spaceAfter = false;
    };
    assert (exists context);
    return context;
}

void writeBacktickClosing(FormattingWriter writer, Token backtick, FormattingWriter.FormattingContext context) {
    assert (backtick.text == "`");
    writer.writeToken {
        backtick;
        linebreaksBefore = noLineBreak;
        spaceBefore = false;
        context;
    };
}

void writeSpecifierMainToken(FormattingWriter writer, Token|String token) {
    writer.writeToken {
        token;
        linebreaksBefore = noLineBreak;
        spaceBefore = true;
        spaceAfter = true;
    };
}

"""Writes a meta literal, for example `` `class Object` `` (where [[start]] would be `"class"`)
   or `` `process` `` (where [[start]] would be [[null]])."""
see (`function writeMetaLiteralStart`)
void writeMetaLiteral(FormattingWriter writer, FormattingVisitor visitor, MetaLiteral that, String? start) {
    value context = writeBacktickOpening(writer, that.mainToken);
    if (exists start) {
        writeMetaLiteralStart(writer, start);
    }
    if (is TypeLiteral that) {
        assert (that.type exists != that.objectExpression exists); // exactly one of these should exist
        that.type?.visit(visitor);
        that.objectExpression?.visit(visitor);
    } else if (is MemberLiteral that) {
        if (that.type exists || that.objectExpression exists) {
            assert (that.type exists != that.objectExpression exists); // only one of these should exist
            that.type?.visit(visitor);
            that.objectExpression?.visit(visitor);
            writer.writeToken {
                ".";
                spaceBefore = false;
                spaceAfter = false;
                linebreaksBefore = noLineBreak;
                linebreaksAfter = noLineBreak;
            };
        }
        that.identifier.visit(visitor);
        that.typeArgumentList?.visit(visitor);
    } else if (is ModuleLiteral that) {
        that.importPath.visit(visitor);
    } else {
        assert (is PackageLiteral that);
        that.importPath.visit(visitor);
    }
    writeBacktickClosing(writer, that.mainEndToken, context);
}

"""Writes the start of a meta literal, for example the `class` or `module`
   of `` `class Object` `` or `` `module ceylon.language` ``."""
void writeMetaLiteralStart(FormattingWriter writer, String start) {
    writer.writeToken {
        start;
        linebreaksBefore = noLineBreak;
        indentAfter = Indent(1);
        spaceBefore = false;
        spaceAfter = true;
    };
}

void writeModifier(FormattingWriter writer, Token modifier) {
    writer.writeToken {
        modifier;
        linebreaksBefore = 0..2;
        spaceBefore = maxDesire - 1;
        spaceAfter = maxDesire - 1;
    };
}

void writeSemicolon(FormattingWriter writer, Token semicolon, FormattingWriter.FormattingContext context) {
    assert(semicolon.text == ";");
    writer.writeToken {
        semicolon;
        linebreaksBefore = noLineBreak;
        linebreaksAfter = 0..2;
        spaceBefore = false;
        spaceAfter = true;
        context;
    };
}

"Write an optional `<` before `inner` and an optional `>` after.
 For grouped types (`{<String->String>*}`)."
void writeOptionallyGrouped(FormattingWriter writer, Anything() inner) {
    variable value context = writer.writeToken {
        "<";
        linebreaksAfter = noLineBreak;
        spaceAfter = false;
        optional = true;
    };
    while (exists c=context) {
        context = writer.writeToken {
            "<";
            linebreaksAfter = noLineBreak;
            spaceAfter = false;
            optional = true;
        };
    }
    inner();
    context = writer.writeToken {
        ">";
        linebreaksBefore = noLineBreak;
        spaceBefore = false;
        optional = true;
    };
    while (exists c=context) {
        context = writer.writeToken {
            ">";
            linebreaksBefore = noLineBreak;
            spaceBefore = false;
            optional = true;
        };
    }
}

void writeSomeMemberOp(FormattingWriter writer, Token token) {
    assert (token.text in { ".", "?.", "*." });
    writer.writeToken {
        token;
        indentBefore = Indent(1);
        linebreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
}
