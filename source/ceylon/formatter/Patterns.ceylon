import org.antlr.runtime { Token }
import com.redhat.ceylon.compiler.typechecker.tree { Tree { ... }, Visitor }
import ceylon.formatter.options { FormattingOptions }
import ceylon.interop.java { CeylonIterable }


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
        indentBefore = 2; // TODO option
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
        indentAfter = 1;
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
        indentBefore = 1;
        linebreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
}

void writeTypeArgumentOrParameterList(FormattingWriter writer, Visitor visitor, TypeArgumentList|TypeParameterList list, FormattingOptions options) {
    value context = writer.openContext();
        writer.writeToken {
            list.mainToken; // "<"
            indentAfter = 1;
            linebreaksAfter = noLineBreak;
            spaceBefore = false;
            spaceAfter = false;
        };
        [Type|TypeParameterDeclaration*] params;
        if (is TypeArgumentList list) {
            params = CeylonIterable(list.types).sequence;
        } else {
            assert (is TypeParameterList list); // TODO remove
            params = CeylonIterable(list.typeParameterDeclarations).sequence;
        }
        assert (nonempty params);
        params.first.visit(visitor);
        for (param in params.rest) {
            writer.writeToken {
                ",";
                spaceBefore = false;
                spaceAfter = options.spaceAfterTypeArgOrParamListComma;
                linebreaksAfter = options.typeParameterListLineBreaks;
            };
            param.visit(visitor);
        }
        writer.writeToken {
            list.mainEndToken; // ">"
            context;
            linebreaksBefore = noLineBreak;
            spaceBefore = false;
            optional = true; // an optionally grouped type might already have eaten the closing angle bracket
        };
        writer.closeContext(context);
}

void writeBinaryOpWithSpecialSpaces(FormattingWriter writer, Visitor visitor, RangeOp|SegmentOp|EntryOp that) {
    Term left = (that of BinaryOperatorExpression).leftTerm;
    Term right = (that of BinaryOperatorExpression).rightTerm;
    Boolean wantsSpaces = wantsSpecialSpaces({ left, right });
    left.visit(visitor);
    writer.writeToken {
        that.mainToken; // "..", ":" or "->"
        linebreaksBefore = noLineBreak;
        linebreaksAfter = noLineBreak;
        spaceBefore = wantsSpaces;
        spaceAfter = wantsSpaces;
    };
    right.visit(visitor);
}

"Special spacing rules for range operators: `1..2` and `3 - 2 .. 4 - 2` are both correctly formatted.
 See issue [#35](https://github.com/lucaswerkmeister/ceylon.formatter/issues/35)."
Boolean wantsSpecialSpaces({Term*} terms) {
    variable Boolean wantsSpaces = false;
    for (term in terms) {
        if (!wantsSpaces) {
            wantsSpaces = !(term is Atom|Primary);
        }
    }
    return wantsSpaces;
}
