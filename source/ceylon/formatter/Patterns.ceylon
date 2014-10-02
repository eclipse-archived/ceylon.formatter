import org.antlr.runtime {
    Token
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree { ... },
    Visitor
}
import ceylon.formatter.options {
    FormattingOptions,
    stack,
    addIndentBefore
}
import ceylon.interop.java {
    CeylonIterable
}


/*
 TODO
 remove assertions before release; they’re probably useful for finding bugs,
 but impact performance negatively
 */

FormattingWriter.FormattingContext writeBacktickOpening(FormattingWriter writer, Token backtick) {
    assert (backtick.text == "`");
    value context = writer.writeToken {
        backtick;
        lineBreaksAfter = noLineBreak;
        spaceAfter = false;
    };
    assert (exists context);
    return context;
}

void writeBacktickClosing(FormattingWriter writer, Token backtick, FormattingWriter.FormattingContext context) {
    assert (backtick.text == "`");
    writer.writeToken {
        backtick;
        lineBreaksBefore = noLineBreak;
        spaceBefore = false;
        context;
    };
}

FormattingWriter.FormattingContext writeSpecifierMainToken(FormattingWriter writer, Token|String token, FormattingOptions options) {
    FormattingWriter.FormattingContext? context;
    switch (options.indentationAfterSpecifierExpressionStart)
    case (stack) {
        context = writer.writeToken {
            token;
            indentBefore = 2; // TODO option
            indentAfter = 1; // see #37
            indentAfterOnlyWhenLineBreak = true; // see #37
            spaceBefore = true;
            spaceAfter = true;
        };
    }
    case (addIndentBefore) {
        context = writer.writeToken {
            token;
            indentBefore = 2; // TODO option
            nextIndentBefore = 2; // see #37
            spaceBefore = true;
            spaceAfter = true;
        };
    }
    assert (exists context);
    return context;
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
                lineBreaksBefore = noLineBreak;
                lineBreaksAfter = noLineBreak;
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
        lineBreaksBefore = noLineBreak;
        indentAfter = 1;
        spaceBefore = false;
        spaceAfter = true;
    };
}

FormattingWriter.FormattingContext? writeModifier(FormattingWriter writer, Token modifier) {
    return writer.writeToken {
        modifier;
        lineBreaksBefore = 0..2;
        spaceBefore = maxDesire - 1;
        spaceAfter = maxDesire - 1;
    };
}

void writeSemicolon(FormattingWriter writer, Token semicolon, FormattingWriter.FormattingContext context) {
    assert (semicolon.text == ";");
    writer.writeToken {
        semicolon;
        lineBreaksBefore = noLineBreak;
        lineBreaksAfter = writer.tokens exists then 0..2 else 1..0;
        spaceBefore = false;
        spaceAfter = true;
        context;
    };
}

void writeSomeMemberOp(FormattingWriter writer, Token token) {
    assert (token.text in { ".", "?.", "*." });
    writer.writeToken {
        token;
        indentBefore = 1;
        lineBreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
}

void writeTypeArgumentOrParameterList(FormattingWriter writer, Visitor visitor, TypeArgumentList|TypeParameterList list, FormattingOptions options) {
    value context = writer.openContext();
    writer.writeToken {
        list.mainToken; // "<"
        indentAfter = 1;
        lineBreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
    [Type|TypeParameterDeclaration*] params;
    if (is TypeArgumentList list) {
        params = CeylonIterable(list.types).sequence();
    } else {
        assert (is TypeParameterList list); // TODO remove
        params = CeylonIterable(list.typeParameterDeclarations).sequence();
    }
    assert (nonempty params);
    params.first.visit(visitor);
    for (param in params.rest) {
        writer.writeToken {
            ",";
            spaceBefore = false;
            spaceAfter = options.spaceAfterTypeArgOrParamListComma;
            lineBreaksAfter = options.lineBreaksInTypeParameterList;
        };
        param.visit(visitor);
    }
    writer.writeToken {
        list.mainEndToken; // ">"
        context;
        lineBreaksBefore = noLineBreak;
        spaceBefore = false;
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
        lineBreaksBefore = noLineBreak;
        lineBreaksAfter = noLineBreak;
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

"Terms in string templates might sometimes require spacing to disambiguate the syntax
 even if [[wantsSpecialSpaces]] says they don’t want spaces. For more information, see
 [ceylon-compiler#959](https://github.com/ceylon/ceylon-compiler/issues/959) or
 [ceylon-compiler#686](https://github.com/ceylon/ceylon-compiler/issues/686)."
see (`function wantsSpecialSpaces`)
Boolean wantsSpacesInStringTemplate(Term term) {
    variable Boolean startsWithBacktick = false;
    object startsWithBacktickVisitor extends GoLeftVisitor() {
        shared actual void visitAliasLiteral(AliasLiteral that) => startsWithBacktick = true;
        shared actual void visitClassLiteral(ClassLiteral that) => startsWithBacktick = true;
        shared actual void visitFunctionLiteral(FunctionLiteral that) => startsWithBacktick = true;
        shared actual void visitInterfaceLiteral(InterfaceLiteral that) => startsWithBacktick = true;
        shared actual void visitMetaLiteral(MetaLiteral that) => startsWithBacktick = true;
        shared actual void visitModuleLiteral(ModuleLiteral that) => startsWithBacktick = true;
        shared actual void visitPackageLiteral(PackageLiteral that) => startsWithBacktick = true;
        shared actual void visitTypeParameterLiteral(TypeParameterLiteral that) => startsWithBacktick = true;
        shared actual void visitValueLiteral(ValueLiteral that) => startsWithBacktick = true;
    }
    term.visit(startsWithBacktickVisitor);
    return startsWithBacktick || wantsSpecialSpaces { term };
}
